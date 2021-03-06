(ns ^{:doc "Application Description Language: generate Postgres database definition."
      :author "Simon Brooke"}
  adl.to-psql
  (:require [adl-support.core :refer :all]
            [adl-support.utils :refer :all]
            [adl.to-hugsql-queries :refer [queries]]
            [clojure.java.io :refer [file make-parents writer]]
            [clojure.string :as s]
            [clojure.xml :as x]
            [clj-time.core :as t]
            [clj-time.format :as f]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; adl.to-psql: generate Postgres database definition.
;;;;
;;;; This program is free software; you can redistribute it and/or
;;;; modify it under the terms of the GNU General Public License
;;;; as published by the Free Software Foundation; either version 2
;;;; of the License, or (at your option) any later version.
;;;;
;;;; This program is distributed in the hope that it will be useful,
;;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;; GNU General Public License for more details.
;;;;
;;;; You should have received a copy of the GNU General Public License
;;;; along with this program; if not, write to the Free Software
;;;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
;;;; USA.
;;;;
;;;; Copyright (C) 2018 Simon Brooke
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; this is a pretty straight translation of adl2psql.xslt, and was written because
;;; Clojure is easier to debug.

(declare emit-field-type emit-property)


(defn emit-defined-field-type
  "Generate appropriate field type and constraints for this `property`
  given this `typedef`."
  [property application]
  (let [typedef (typedef property application)]
    ;; this is a hack based on the fact that emit-field-type doesn't check
    ;; that the argument passed as `property` is indeed a property.
    (str (emit-field-type typedef nil application false)
         (cond
           (:pattern (:attrs typedef))
           (str
             " CONSTRAINT "
             (gensym "pattern_")
             " CHECK ("
             (:name (:attrs property))
             " ~* '"
             (:pattern (:attrs typedef))
             "')")
           (and (:maximum (:attrs typedef))(:minimum (:attrs typedef)))
           ;; TODO: if base type is date, time or timestamp, values should be quoted.
           (str
             " CONSTRAINT "
             (gensym "minmax_")
             " CHECK ("
             (:minimum (:attrs typedef))
             " < "
             (:name (:attrs property))
             " AND "
             (:name (:attrs property))
             " < "
             (:maximum (:attrs typedef))
             ")")
           (:maximum (:attrs typedef))
           (str
             " CONSTRAINT "
             (gensym "max_")
             " CHECK ("
             (:name (:attrs property))
             " < "
             (:maximum (:attrs typedef))
             ")")
           (:minimum (:attrs typedef))
           (str
             " CONSTRAINT "
             (gensym "min_")
             " CHECK ("
             (:minimum (:attrs typedef))
             " < "
             (:name (:attrs property)))))))


(defn emit-entity-field-type
  "Emit an appropriate field type for this `property`, expected to reference an entity, in this `application`."
  [property application]
  (let [farside (entity-for-property property application)
        key-properties (children-with-tag
                         (first (children-with-tag farside :key))
                         :property)]
    (if
      (> (count key-properties) 1)
      (str
        "-- ERROR: cannot generate link to entity "
        (:name (:attrs farside))
        " with compound primary key\n")
      (emit-field-type (first key-properties) farside application false))))


(defn emit-field-type
  "Emit an appropriate field type for this `property`, expected to belong to
  this `entity` within this `application`."
  [property entity application key?]
  (case (:type (:attrs property))
    "integer" (if
                (and
                 key?
                 (system-generated? property))
                "SERIAL"
                "INTEGER")
    "real" "DOUBLE PRECISION"
    ("string" "image" "uploadable")
    (str "VARCHAR(" (:size (:attrs property)) ")")
    "defined" (emit-defined-field-type property application)
    "entity" (emit-entity-field-type property application)
    ("date" "time" "timestamp" "boolean" "text" "money")
    (.toUpperCase (:type (:attrs property)))
    (str "-- ERROR: unknown type " (:type (:attrs property)))))


(defn emit-link-field
  "Emit an appropriate link field for this `property` of this `entity`
  within this `application`."
  [property entity application]
  (emit-property
    {:tag :property
     :attrs {:name (str (:name (:attrs entity)) "_id")
             :type "entity"
             :entity (:name (:attrs entity))
             :cascade (:cascade (:attrs property))}}
    entity
    application))


(defn emit-permissions-grant
  "Emit an appropriate grant of permissions on this `table-name` at this
  `privilege` level given these `permissions`. `privilege` is expected
  to be one of #{:SELECT :INSERT :UPDATE :DELETE}.
  TODO: more thought needed here."
  [table-name privilege permissions]
  (let [selector
        (case privilege
          :SELECT #{"read" "noedit" "edit" "all"}
          :INSERT #{"insert" "noedit" "edit" "all"}
          :UPDATE #{"edit" "all"}
          (:DELETE :ALL) #{"all"})
        group-names
        (set
          (remove
            nil?
            (map
              #(if (selector (:permission (:attrs %)))
                 (safe-name (:group (:attrs %)) :sql))
              permissions)))]
    (if-not
      (empty? group-names)
      (s/join
        " "
        (list
          "GRANT"
          (name privilege)
          "ON"
          (safe-name table-name :sql)
          "TO"
          (s/join
            ",\n\t"
            (sort group-names))
          ";")))))


(defn field-name
  "Return the appropriate field name for this `property`.
  TODO: really belongs in `adl-support.utils`."
  [property]
  (safe-name
    (or
      (:column (:attrs property))
      (:name (:attrs property)))
    :sql))


(defn emit-property
  "Emit a field declaration representing this `property` of this `entity` within this `application`."
  ([property entity application]
   (emit-property property entity application false))
  ([property entity application key?]
   (let [default (:default (:attrs property))]
     (if
       (and
         (= (:tag property) :property)
         (not (#{"link"} (:type (:attrs property)))))
       (s/join
         " "
         (remove
           nil?
           (flatten
             (list
               "\t"
               (field-name property)
               (emit-field-type property entity application key?)
               (if
                 default
                 (list
                   "DEFAULT"
                   (if
                     (is-quotable-type? property application)
                     (str "'" default "'") ;; TODO: but if the default value seems to be a function invocation, should it be quoted?
                     ;; it's quite common for 'now()' to be the default for a date, time or timestamp field.
                     default)))
               (if
                 key?
                 "NOT NULL PRIMARY KEY"
                 (if (= (:required (:attrs property)) "true") "NOT NULL"))))))))))


(defn compose-convenience-entity-field
  [field entity application]
  (let [farside (entity-for-property (property-for-field field entity) application)]
    (flatten
      (map
        (fn [f]
          (if
            (= (:type (:attrs f)) "entity")
            (compose-convenience-entity-field f farside application)
            (str (safe-name (:table (:attrs farside))) "." (field-name f))))
        (user-distinct-properties farside)))))


(defn compose-convenience-view-select-list
  "Compose the body of an SQL `SELECT` statement for a convenience view of this
  `entity` within this `application`, recursively. `top-level?` should be set
  only on first invocation."
  [entity application top-level?]
  (remove
    nil?
    (flatten
      (cons
        (safe-name (:table (:attrs entity)) :sql)
        (map
          (fn [f]
            (if
              (= (:type (:attrs f)) "entity")
              (compose-convenience-view-select-list
                (child application #(and (entity? %) (= (:name (:attrs %))(:entity (:attrs f)))))
                application
                false)))
          (if
            top-level?
            (all-properties entity)
            (user-distinct-properties entity)))))))


(defn compose-convenience-where-clause
  "Compose an SQL `WHERE` clause for a convenience view of this
  `entity` within this `application`.
  TODO: does not correctly compose links at one stage down the tree.
  See `lv_electors`, `lv_followuprequests` for examples of the problem."
  [entity application top-level?]
  (remove
    nil?
    (flatten
      (map
        (fn [f]
          (if
            (= (:type (:attrs f)) "entity")
            (let [farside (entity-for-property f application)]
              (cons
                (str
                  (safe-name (:table (:attrs entity)) :sql)
                  "."
                  (field-name f)
                  " = "
                  (safe-name (:table (:attrs farside)) :sql)
                  "."
                  (safe-name (first (key-names farside)) :sql))
                #(compose-convenience-where-clause farside application false)))))
        (if
          top-level?
          (all-properties entity)
          (user-distinct-properties entity))))))


(defn emit-convenience-entity-field
  [field entity application]
  (str
    (s/join
      " ||', '|| "
      (compose-convenience-entity-field field entity application))
    " AS "
    (field-name field)
    "_expanded"))


(defn emit-convenience-view
  "Emit a convenience view of this `entity` of this `application` for use in generating lists,
  menus, et cetera."
  [entity application]
  (let [view-name (safe-name (str "lv_" (:table (:attrs entity))) :sql)
        entity-fields (filter
                        #(= (:type (:attrs %)) "entity")
                        (properties entity))]
    (s/join
      "\n"
      (remove
        nil?
        (flatten
          (list
            (emit-header
              "--"
              (str "convenience view " view-name " of entity " (:name (:attrs entity)) " for lists, et cetera"))
            (s/join
              " "
              (list "CREATE VIEW" view-name "AS"))
            (str
              "SELECT "
              (s/join
                ",\n\t"
                (flatten
                  (map
                    #(if
                       (= (:type (:attrs %)) "entity")
                       (list
                         (emit-convenience-entity-field % entity application)
                         (str (safe-name entity) "." (field-name %)))
                       (str (safe-name entity) "." (field-name %)))
                    (filter
                      #(not= (:type (:attrs %)) "link")
                      (all-properties entity) )))))
            (str
              "FROM " (s/join ", " (set (compose-convenience-view-select-list entity application true))))
            (if-not
              (empty? entity-fields)
              (str
                "WHERE "
                (s/join
                  "\n\tAND "
                  (map
                    (fn [f]
                      (let
                        [farside (entity-for-property f application)]
                        (str
                          (safe-name (:table (:attrs entity)) :sql)
                          "."
                          (field-name f)
                          " = "
                          (safe-name (:table (:attrs farside)) :sql)
                          "."
                          (safe-name (first (key-names farside)) :sql))))
                    entity-fields))))
            ";"
            (emit-permissions-grant view-name :SELECT (find-permissions entity application))))))))


(defn emit-referential-integrity-link
  "Emit a referential integrity link for this `property` of the entity
  `nearside` within this `application`."
  [property nearside application]
  (let
    [farside (entity-for-property property application)]
    (s/join
      " "
      (list
        "ALTER TABLE"
        (safe-name (:name (:attrs nearside)) :sql)
        "ADD CONSTRAINT"
        (safe-name (str "ri_" (:name (:attrs nearside)) "_" (:name (:attrs farside)) "_" (:name (:attrs property))) :sql)
        "\n\tFOREIGN KEY("
        (field-name property)
        ") \n\tREFERENCES"
        (str
          (safe-name (:table (:attrs farside)) :sql)
          "(" (field-name (first (key-properties farside))) ")")
        ;; TODO: ought to handle the `cascade` attribute, even though it's rarely used
        "\n\tON DELETE"
        (case
          (:cascade (:attrs property))
          "orphan" "SET NULL"
          "delete" "CASCADE"
          "NO ACTION")
        ";"))))


(defn emit-referential-integrity-links
  "Emit all appropriate referential integrity links for this `entity`
  within this `application`."
  ([entity application]
   (map
     #(emit-referential-integrity-link % entity application)
     (sort-by-name
       (filter
         #(= (:type (:attrs %)) "entity")
         (properties entity)))))
  ([application]
   (flatten
     (list
       (emit-header
         "--"
         "referential integrity links for primary tables")
       (map
         #(emit-referential-integrity-links % application)
         (sort-by-name (children-with-tag application :entity)))))))


(defn emit-table
  "Emit a table declaration for this `entity` of this `application`,
  documented with this `doc-comment` if specified."
  ([entity application doc-comment]
   (let [table-name (safe-name (:table (:attrs entity)) :sql)
         permissions (children-with-tag entity :permission)]
     (s/join
       "\n"
       (flatten
         (list
           (emit-header
             "--"
             (list
               doc-comment
               (map
                 :content
                 (children-with-tag entity :documentation))))
           (s/join
             " "
             (list "CREATE TABLE" table-name))
           "("
           (str
             (s/join
               ",\n"
               (flatten
                 (remove
                   nil?
                   (list
                     (map
                       #(emit-property % entity application true)
                       (children-with-tag (child-with-tag entity :key) :property))
                     (map
                       #(emit-property % entity application false)
                       (filter
                         #(not= (:type (:attrs %)) "link")
                         (children-with-tag entity :property)))))))
             "\n);")
           (map
             #(emit-permissions-grant table-name % permissions)
             '(:SELECT :INSERT :UPDATE :DELETE)))))))
  ([entity application]
   (emit-table
     entity
     application
     (str
       "primary table "
       (:table (:attrs entity))
       " for entity "
       (:name (:attrs entity))))))


(defn construct-link-property
  "Create a dummy property for a link-table referencing this `entity`, in order
  that the field generation functions already defined may be applied to it."
  [entity]
  {:tag :property
   :attrs {:name (safe-name (str (singularise (:name (:attrs entity))) "_id") :sql)
           :column (safe-name (str (singularise (:name (:attrs entity))) "_id") :sql)
           :type "entity"
           :entity (:name (:attrs entity))
           :farkey (safe-name (first (key-names entity)) :sql)}})


(defn emit-link-table
  "Emit a link table for the specified `property` of the entity `e1` within
  this `application`, provided that such a table has not already been emitted
  from the other end. The argument `emitted-link-tables` contains an atom
  which references a set of the names of all those link tables which have
  already been emitted, and this is modified in the execution of this function."
  [property e1 application emitted-link-tables]
  (let [e2 (child
             application
             #(and
                (entity? %)
                (= (:name (:attrs %)) (:entity (:attrs property)))))
        unique? (unique-link? e1 e2)
        link-table-name (link-table-name property e1 e2)]
    (if
      ;; we haven't already emitted this one...
      (not (@emitted-link-tables link-table-name))
      (let [permissions (flatten
                          (list
                            (children-with-tag e1 :permission)
                            (children-with-tag e1 :permission)))
            ;; construct a dummy entity
            link-entity {:tag :entity
                         :attrs {:name link-table-name
                                 :table link-table-name}
                         :content
                         (apply vector
                                (flatten
                                  (list
                                    [(construct-link-property e1)
                                     (construct-link-property e2)]
                                    permissions)))}]
        (if-not unique?
          (*warn*
           (str "WARNING: Manually check link tables between "
                (-> e1 :attrs :name)
                " and "
                (-> e2 :attrs :name)
                " for redundancy")))
        ;; mark it as emitted
        (swap! emitted-link-tables conj link-table-name)
        ;; emit it
        (flatten
          (list
            (emit-table
              link-entity
              application
              (str
                "link table joining "
                (:name (:attrs e1))
                " with "
                (:name (:attrs e2))))
                       ;; and immediately emit its referential integrity links
            (emit-referential-integrity-links link-entity application)))))))


(defn emit-link-tables
  "Emit all required link tables for this `entity` within this `application`,
  given these `emitted-link-tables` which have already been emitted."
  ([entity application emitted-link-tables]
   (map
     #(emit-link-table % entity application emitted-link-tables)
     (sort-by-name
       (filter
         #(= (:type (:attrs %)) "link")
         (properties entity)))))
  ([application emitted-link-tables]
   (map
     #(emit-link-tables % application emitted-link-tables)
     (sort-by-name (children-with-tag application :entity)))))


(defn emit-group-declaration
  "Emit a declaration for this authorisation `group` within this `application`."
  [group application]
  (list
    (emit-header
      "--"
      (str "security group " (:name (:attrs group))))
    (str "CREATE GROUP " (safe-name (:name (:attrs group)) :sql) ";")))


(defn emit-file-header
  "Generate an appropriate file header for the Postgres initialisation script
  for this `application`."
  [application]
  (emit-header
    "--"
    "Database definition for application "
    (str (:name (:attrs application))
         " version "
         (:version (:attrs application)))
    "auto-generated by [Application Description Language framework]"
    (str "(https://github.com/simon-brooke/adl) at "
         (f/unparse (f/formatters :basic-date-time) (t/now)))
    (map
      :content
      (children-with-tag application :documentation))))


(defn emit-application
  "Emit all SQL declarations required to initialise a Postgres database for
  this `application`."
  [application]
  (let [emitted-link-tables (atom #{})]
    (s/join
      "\n\n"
      (flatten
        (list
          (emit-file-header application)
          (map
            #(emit-group-declaration % application)
            (sort-by-name
              (children-with-tag application :group)))
          (map
            #(emit-table % application)
            (sort-by-name
              (children-with-tag application :entity)))
          (map
            #(emit-convenience-view % application)
            (sort-by-name
              (children-with-tag application :entity)))
          (emit-referential-integrity-links application)
          (emit-link-tables application emitted-link-tables))))))


(defn to-psql
  "Generate a complete Postgres database initialisation script for this `application`."
  [application]
  (let [filepath (str
                   *output-path*
                   "resources/sql/"
                   (:name (:attrs application))
                   ".postgres.sql")]
    (make-parents filepath)
    (do-or-warn
      (spit filepath (emit-application application))
      (if
        (pos? *verbosity*)
        (*warn* (str "\tGenerated " filepath))))))


