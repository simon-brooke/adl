(ns ^{:doc "Application Description Language - generate HUGSQL queries file."
      :author "Simon Brooke"}
  adl.to-hugsql-queries
  (:require [clojure.java.io :refer [file make-parents]]
            [clojure.math.combinatorics :refer [combinations]]
            [clojure.string :as s]
            [clojure.xml :as x]
            [clj-time.core :as t]
            [clj-time.format :as f]
            [adl-support.utils :refer :all]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; adl.to-hugsql-queries: generate HUGSQL queries file.
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


(defn where-clause
  "Generate an appropriate `where` clause for queries on this `entity`;
  if `properties` are passed, filter on those properties, otherwise the key
  properties."
  ([entity]
   (where-clause entity (key-properties entity)))
  ([entity properties]
   (let
     [entity-name (:name (:attrs entity))
      property-names (map #(:name (:attrs %)) properties)]
     (if
       (not (empty? property-names))
       (str
         "WHERE "
         (s/join
           "\n\tAND"
           (map #(str entity-name "." % " = :" %) property-names)))))))


(defn order-by-clause
  "Generate an appropriate `order by` clause for queries on this `entity`"
  ([entity]
   (order-by-clause entity ""))
  ([entity prefix]
  (let
    [entity-name (safe-name (:name (:attrs entity)) :sql)
     preferred (map
                 #(safe-name (:name (:attrs %)) :sql)
                 (filter #(#{"user" "all"} (-> % :attrs :distinct))
                         (children entity #(= (:tag %) :property))))]
    (if
      (empty? preferred)
      ""
      (str
        "ORDER BY " prefix entity-name "."
        (s/join
          (str ",\n\t" prefix entity-name ".")
          (map
            #(safe-name % :sql)
            (flatten (cons preferred (key-names entity))))))))))


(defn insert-query
  "Generate an appropriate `insert` query for this `entity`.
  TODO: this depends on the idea that system-unique properties
  are not insertable, which is... dodgy."
  [entity]
  (let [entity-name (safe-name (:name (:attrs entity)) :sql)
        pretty-name (singularise entity-name)
        insertable-property-names (map
                                    #(safe-name (:name (:attrs %)) :sql)
                                    (insertable-properties entity))
        query-name (str "create-" pretty-name "!")
        signature ":! :n"]
    (hash-map
      (keyword query-name)
      {:name query-name
       :signature signature
       :entity entity
       :type :insert-1
       :query
       (str "-- :name " query-name " " signature "\n"
            "-- :doc creates a new " pretty-name " record\n"
            "INSERT INTO " entity-name " ("
            (s/join ",\n\t" insertable-property-names)
            ")\nVALUES ("
            (s/join ",\n\t" (map keyword insertable-property-names))
            ")"
            (if
              (has-primary-key? entity)
              (str "\nreturning "
                   (s/join
                     ",\n\t"
                     (map
                       #(safe-name % :sql)
                           (key-names entity))))))})))


(defn update-query
  "Generate an appropriate `update` query for this `entity`"
  [entity]
  (if
    (and
      (has-primary-key? entity)
      (has-non-key-properties? entity))
    (let [entity-name (safe-name (:name (:attrs entity)) :sql)
          pretty-name (singularise entity-name)
          property-names (map #(:name (:attrs %)) (insertable-properties entity))
          query-name (str "update-" pretty-name "!")
          signature ":! :n"]
      (hash-map
        (keyword query-name)
        {:name query-name
         :signature signature
         :entity entity
         :type :update-1
         :query
         (str "-- :name " query-name " " signature "\n"
              "-- :doc updates an existing " pretty-name " record\n"
              "UPDATE " entity-name "\n"
              "SET "
              (s/join ",\n\t" (map #(str (safe-name % :sql) " = " (keyword %)) property-names))
              "\n"
              (where-clause entity))}))
    {}))


(defn search-query [entity application]
  "Generate an appropriate search query for string fields of this `entity`"
  (let [entity-name (safe-name (:name (:attrs entity)) :sql)
        pretty-name (singularise entity-name)
        query-name (str "search-strings-" entity-name)
        signature ":? :1"
        properties (remove #(#{"link"}(:type (:attrs %))) (all-properties entity))]
    (hash-map
      (keyword query-name)
      {:name query-name
       :signature signature
       :entity entity
       :type :text-search
       :query
       (s/join
         "\n"
         (remove
           empty?
           (list
             (str "-- :name " query-name " " signature)
             (str
               "-- :doc selects existing "
               pretty-name
               " records having any string field matching the parameter of the same name by substring match")
             (str "SELECT DISTINCT * FROM lv_" entity-name)
             (s/join
               "\n\t--~ "
               (cons
                 "WHERE false"
                 (filter
                   string?
                   (map
                     #(str
                        "(if (:" (-> % :attrs :name) " params) \"OR "
                        (case (base-type % application)
                          ("string" "text")
                          (str
                            (safe-name (-> % :attrs :name) :sql)
                            " LIKE '%:" (-> % :attrs :name) "%'")
                          ("date" "time" "timestamp")
                          (str
                            (safe-name (-> % :attrs :name) :sql)
                            " = ':" (-> % :attrs :name) "'")
                          "entity"
                          (str
                           (safe-name (-> % :attrs :name) :sql)
                            "_expanded LIKE '%:" (-> % :attrs :name) "%'")
                          (str
                            (safe-name (-> % :attrs :name) :sql)
                            " = :"
                            (-> % :attrs :name)))
                        "\")")
                     properties))))
               (order-by-clause entity "lv_")
               "--~ (if (:offset params) \"OFFSET :offset \")"
               "--~ (if (:limit params) \"LIMIT :limit\" \"LIMIT 100\")")))})))


(defn select-query
  "Generate an appropriate `select` query for this `entity`"
  ([entity properties]
   (if
     (not (empty? properties))
     (let [entity-name (safe-name (:name (:attrs entity)) :sql)
           pretty-name (singularise entity-name)
           query-name (if (= properties (key-properties entity))
                        (str "get-" pretty-name)
                        (str "get-" pretty-name "-by-" (s/join "=" (map #(:name (:attrs %)) properties))))
           signature ":? :1"]
       (hash-map
         (keyword query-name)
         {:name query-name
          :signature signature
          :entity entity
          :type :select-1
          :query
          (s/join
            "\n"
            (remove
              empty?
              (list
                (str "-- :name " query-name " " signature)
                (str "-- :doc selects an existing " pretty-name " record")
                (str "SELECT * FROM " entity-name)
                (where-clause entity properties)
                (order-by-clause entity))))}))
     {}))
  ([entity]
   (let [distinct-fields (distinct-properties entity)]
     (apply
       merge
       (cons
         (select-query entity (key-properties entity))
         (map
           #(select-query entity %)
           (combinations distinct-fields (count distinct-fields))))))))


(defn list-query
  "Generate a query to list records in the table represented by this `entity`.
  Parameters `:limit` and `:offset` may be supplied. If not present limit defaults
  to 100 and offset to 0."
  [entity]
  (let [entity-name (safe-name (:name (:attrs entity)) :sql)
        pretty-name (singularise entity-name)
        query-name (str "list-" entity-name)
        signature ":? :*"]
    (hash-map
      (keyword query-name)
      {:name query-name
       :signature signature
       :entity entity
       :type :select-many
       :query
       (s/join
         "\n"
         (remove
           empty?
           (list
             (str "-- :name " query-name " " signature)
             (str "-- :doc lists all existing " pretty-name " records")
             (str "SELECT DISTINCT * FROM lv_" entity-name)
             (order-by-clause entity "lv_")
             "--~ (if (:offset params) \"OFFSET :offset \")"
             "--~ (if (:limit params) \"LIMIT :limit\" \"LIMIT 100\")")))})))


(defn foreign-queries
  [entity application]
  (let [entity-name (:name (:attrs entity))
        pretty-name (singularise entity-name)
        links (filter #(#{"link" "entity"} (:type (:attrs %))) (children-with-tag entity :property))]
    (apply
      merge
      (map
        #(let [far-name (:entity (:attrs %))
               far-entity (first
                            (children
                              application
                              (fn [x]
                                (and
                                  (= (:tag x) :entity)
                                  (= (:name (:attrs x)) far-name)))))
               pretty-far (singularise far-name)
               farkey (-> % :attrs :farkey)
               link-type (-> % :attrs :type)
               link-field (-> % :attrs :name)
               query-name (str "list-" entity-name "-by-" pretty-far)
               signature ":? :*"]
           (hash-map
             (keyword query-name)
             {:name query-name
              :signature signature
              :entity entity
              :type :select-one-to-many
              :far-entity far-entity
              :query
              (s/join
                "\n"
                (remove
                  empty?
                  (case link-type
                    "entity" (list
                               (str "-- :name " query-name " " signature)
                               (str "-- :doc lists all existing " pretty-name " records related to a given " pretty-far)
                               (str "SELECT * \nFROM lv_" entity-name ", " entity-name)
                               (str "WHERE lv_" entity-name "." (first (key-names entity)) " = "
                                    entity-name "." (first (key-names entity))
                                    "\n\tAND " entity-name "." link-field " = :id")
                               (order-by-clause entity "lv_"))
                    "link" (let [link-table-name
                                 (link-table-name entity far-entity)]
                             (list
                               (str "-- :name " query-name " " signature)
                               (str "-- :doc links all existing " pretty-name " records related to a given " pretty-far)
                               (str "SELECT * \nFROM " entity-name ", " link-table-name)
                               (str "WHERE " entity-name "."
                                    (first (key-names entity))
                                    " = " link-table-name "." (singularise entity-name) "_id")
                               (str "\tAND " link-table-name "." (singularise far-name) "_id = :id")
                               (order-by-clause entity)))
                    (list (str "ERROR: unexpected type " link-type " of property " %)))))
              }))
        links))))


(defn delete-query [entity]
  "Generate an appropriate `delete` query for this `entity`"
  (if
    (has-primary-key? entity)
    (let [entity-name (:name (:attrs entity))
          pretty-name (singularise entity-name)
          query-name (str "delete-" pretty-name "!")
          signature ":! :n"]
      (hash-map
        (keyword query-name)
        {:name query-name
         :signature signature
         :entity entity
         :type :delete-1
         :query
         (str "-- :name " query-name " " signature "\n"
              "-- :doc updates an existing " pretty-name " record\n"
              "DELETE FROM " entity-name "\n"
              (where-clause entity))}))))


(defn queries
  "Generate all standard queries for this `entity` in this `application`; if
  no entity is specified, generate all queries for the application."
  ([application entity]
   (merge
     ;; TODO: queries that look through link tables
     (insert-query entity)
     (update-query entity)
     (delete-query entity)
     (select-query entity)
     (list-query entity)
     (search-query entity application)
     (foreign-queries entity application)))
  ([application]
   (apply
     merge
     (map #(queries application %)
          (children-with-tag application :entity)))))


(defn to-hugsql-queries
  "Generate all [HugSQL](https://www.hugsql.org/) queries implied by this ADL `application` spec."
  [application]
  (let [filepath (str *output-path* "resources/sql/queries.auto.sql")]
    (make-parents filepath)
    (try
      (spit
        filepath
        (s/join
          "\n\n"
          (cons
            (emit-header
              "--"
              "File queries.sql"
              (str "autogenerated by adl.to-hugsql-queries at " (t/now))
              "See [Application Description Language](https://github.com/simon-brooke/adl).")
            (map
              #(:query %)
              (sort
                #(compare (:name %1) (:name %2))
                (vals
                  (queries application)))))))
      (if (> *verbosity* 0)
        (println (str "\tGenerated " filepath)))
      (catch
        Exception any
        (println
          (str
            "ERROR: Exception "
            (.getName (.getClass any))
            (.getMessage any)
            " while printing "
            filepath))))))

