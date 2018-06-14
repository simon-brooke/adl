(ns ^{:doc "Application Description Language: generate Postgres database definition."
      :author "Simon Brooke"}
  adl.to-psql
  (:require [clojure.java.io :refer [file make-parents writer]]
            [clojure.pprint :refer [pprint]]
            [clojure.string :as s]
            [clojure.xml :as x]
            [clj-time.core :as t]
            [clj-time.format :as f]
            [adl.utils :refer :all]
            [adl.to-hugsql-queries :refer [queries]]))

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

;;; TODO: the order in which we generate tables is critical, because tables
;;; can only reference other tables which already exist. We could get around
;;; this by generating referential integrity constraints post-hoc, which is
;;; what the xslt version did.

(defn sort-by-name
  [elements]
  (sort #(.compareTo (:name (:attrs %1)) (:name (:attrs %2))) elements))


(declare emit-field-type emit-property)


(defn emit-defined-field-type
  [property application]
  (let [typedef (typedef property application)]
    ;; this is a hack based on the fact that emit-field-type doesn't check
    ;; that the argument passed as `property` is indeed a property.
    (str (emit-field-type typedef nil application false)
         (cond
          (:pattern (:attrs typedef))
          (str
           " CONSTRAINT "
           (gensym "c-")
           " CHECK ("
           (:name (:attrs property))
           " ~* '"
           (:pattern (:attrs typedef))
           "')")
          (and (:maximum (:attrs typedef))(:minimum (:attrs typedef)))
          ;; TODO: if base type is date, time or timestamp, values should be quoted.
          (str
           " CONSTRAINT "
           (gensym "c-")
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
           (gensym "c-")
           " CHECK ("
           (:name (:attrs property))
           " < "
           (:maximum (:attrs typedef))
           ")")
          (:minimum (:attrs typedef))
          (str
           " CONSTRAINT "
           (gensym "c-")
           " CHECK ("
           (:minimum (:attrs typedef))
           " < "
           (:name (:attrs property)))))))


(defn emit-entity-field-type
  [property application]
  (let [farside (child
                 application
                 #(and
                   (entity? %)
                   (= (:name (:attrs %)) (:entity (:attrs property)))))
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
  [property entity application key?]
  (case (:type (:attrs property))
    "integer" (if key? "SERIAL" "INTEGER")
    "real" "DOUBLE PRECISION"
    ("string" "image" "uploadable")
              (str "VARCHAR(" (:size (:attrs property)) ")")
    "defined" (emit-defined-field-type property application)
    "entity" (emit-entity-field-type property application)
    ("date" "time" "timestamp" "boolean" "text" "money")
              (.toUpperCase (:type (:attrs property)))
    (str "-- ERROR: unknown type " (:type (:attrs property)))))


(defn emit-link-field
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
              (:group (:attrs %)))
           permissions)))]
    (if
      (not (empty? group-names))
      (s/join " " (list "GRANT" (name privilege) "ON"  table-name "TO" (s/join ",\n\t" (sort group-names)) ";")))))


(defn emit-property
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
           (:name (:attrs property))
           (emit-field-type property entity application key?)
           (if default (list "DEFAULT" default))
           (if
             key?
             "NOT NULL PRIMARY KEY"
             (if (= (:required (:attrs property)) "true") "NOT NULL"))))))))))


(defn compose-convenience-entity-field
  [field entity application]
  (let [farside (child
                 application
                 #(and
                   (entity? %)
                   (= (:name (:attrs %)) (:entity (:attrs field)))))]
    (flatten
     (map
      (fn [f]
        (if
          (= (:type (:attrs f)) "entity")
          (compose-convenience-entity-field f farside application)
          (str (:table (:attrs farside)) "." (:name (:attrs f)))))
      (user-distinct-properties farside)))))


(defn compose-convenience-view-select-list
  [entity application top-level?]
  (remove
   nil?
   (flatten
    (cons
     (:name (:attrs entity))
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
  ;; TODO: does not correctly compose links at one stage down the tree.
  ;; See lv_electors, lv_followuprequests for examples of the problem.
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
             (:table (:attrs entity))
             "."
             (:name (:attrs f))
             " = "
             (:table (:attrs farside))
             "."
             (first (key-names farside)))
            #(compose-convenience-where-clause farside application false)))))
     (if
       top-level?
       (all-properties entity)
       (user-distinct-properties entity))))))


(defn emit-convenience-entity-field
  [field entity application]
  (str
   (s/join
    " |', '| "
    (compose-convenience-entity-field field entity application))
   " AS "
   (:name (:attrs field))))


(defn emit-convenience-view
  "Emit a convenience view of this `entity` of this `application` for use in generating lists,
  menus, et cetera."
  [entity application]
  (let [view-name (str "lv_" (:table (:attrs entity)))
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
          (map
           #(if
              (= (:type (:attrs %)) "entity")
              (emit-convenience-entity-field % entity application)
              (:name (:attrs %)))
           (filter
            #(and (= (:tag %) :property) (not (= (:type (:attrs %)) "link")))
            (all-properties entity) ))))
        (str
         "FROM " (s/join ", " (compose-convenience-view-select-list entity application true)))
        (if
          (not (empty? entity-fields))
          (str
           "WHERE "
           (s/join
            "\n\tAND "
            (map
             (fn [f]
               (let
                 [farside (child
                           application
                           #(and
                             (entity? %)
                             (= (:name (:attrs %)) (:entity (:attrs f)))))]
                 (str
                  (:table (:attrs entity))
                  "."
                  (:name (:attrs f))
                  " = "
                  (:table (:attrs farside))
                  "."
                  (first (key-names farside)))))
             entity-fields))))
        ";"
        (emit-permissions-grant view-name :SELECT (permissions entity application))))))))


(defn emit-referential-integrity-link
  [property nearside application]
  (let
    [farside (entity-for-property property application)]
    (s/join
     " "
     (list
      "ALTER TABLE"
      (:name (:attrs nearside))
      "ADD CONSTRAINT"
      (str "ri_" (:name (:attrs nearside)) "_" (:name (:attrs property)))
      "\n\tFOREIGN KEY("
      (:name (:attrs property))
      ") \n\tREFERENCES"
      (str
       (:table (:attrs farside)) "(" (:name (:attrs (first (key-properties farside)))) ")")
      ;; TODO: ought to handle the `cascade` attribute, even though it's rarely used
      "\n\tON DELETE"
      (case
        (:cascade (:attrs property))
        "orphan" "SET NULL"
        "delete" "CASCADE"
        "NO ACTION")
      ";"))))


(defn emit-referential-integrity-links
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
      (str "--\treferential integrity links for first-class tables"))
     (map
      #(emit-referential-integrity-links % application)
      (sort-by-name (children-with-tag application :entity)))))))


(defn emit-table
  ([entity application doc-comment]
   (let [table-name (:table (:attrs entity))
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
           #(:content %)
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
               #(not (= (:type (:attrs %)) "link"))
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
  [entity]
  {:tag :property
   :attrs {:name (str (:name (:attrs entity)) "_id")
           :column (str (:name (:attrs entity)) "_id")
           :type "entity"
           :entity (:name (:attrs entity))
           :farkey (first (key-names entity))}
   :content nil})


(defn emit-link-table
  [property e1 application emitted-link-tables]
  (let [e2 (child
            application
            #(and
              (entity? %)
              (= (:name (:attrs %)) (:entity (:attrs property)))))
        link-table-name (link-table-name e1 e2)]
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


(defn emit-entity
  [entity application]
  (doall
   (list
    (emit-table entity application)
    (emit-convenience-view entity application))))


(defn emit-group-declaration
  [group application]
  (list
   (emit-header
    "--"
    (str "security group " (:name (:attrs group))))
   (str "CREATE GROUP " (:name (:attrs group)) ";")))


(defn emit-file-header
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
    #(:content %)
    (children-with-tag application :documentation))))


(defn emit-application
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
        #(emit-entity % application)
        (sort-by-name
         (children-with-tag application :entity)))
       (emit-referential-integrity-links application)
       (emit-link-tables application emitted-link-tables))))))


(defn to-psql
  [application]
  (let [filepath (str
                  *output-path*
                  "/resources/sql/"
                  (:name (:attrs application))
                  ".postgres.sql")]
    (make-parents filepath)
    (spit filepath (emit-application application))))


