(ns ^{:doc "Application Description Language - generate HUGSQL queries file."
      :author "Simon Brooke"}
  adl.to-hugsql-queries
  (:require [adl-support.core :refer :all]
            [adl-support.utils :refer :all]
            [clojure.java.io :refer [file make-parents]]
            [clojure.math.combinatorics :refer [combinations]]
            [clojure.string :as s]
            [clojure.xml :as x]
            [clj-time.core :as t]
            [clj-time.format :as f]))

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

(def expanded-token "_expanded")


(defn where-clause
  "Generate an appropriate `where` clause for queries on this `entity`;
  if `properties` are passed, filter on those properties, otherwise the key
  properties."
  ([entity]
   (where-clause entity (key-properties entity)))
  ([entity properties]
   (let
     [entity-name (safe-name entity :sql)
      property-names (map #(:name (:attrs %)) properties)]
     (if-not (empty? property-names)
       (str
         "WHERE "
         (s/join
           "\n\tAND "
           (map
             #(str entity-name "." (safe-name % :sql) " = :" %)
             property-names)))))))


(defn order-by-clause
  "Generate an appropriate `order by` clause for queries on this `entity`"
  ([entity]
   (order-by-clause entity "" false))
  ([entity prefix]
   (order-by-clause entity prefix false))
  ([entity prefix expanded?]
   (let
     [entity-name (safe-name entity :sql)
      preferred (filter #(#{"user" "all"} (-> % :attrs :distinct))
                        (descendants-with-tag entity :property))]
     (if
       (empty? preferred)
       ""
       (str
         "ORDER BY " prefix entity-name "."
         (s/join
           (str ",\n\t" prefix entity-name ".")
           (map
             #(if
                (and expanded? (= "entity" (-> % :attrs :type)))
                (str (safe-name % :sql) expanded-token)
                (safe-name % :sql))
             (order-preserving-set
               (concat
                 preferred
                 (key-properties entity))))))))))

;; (def a (x/parse "../youyesyet/youyesyet.adl.xml"))
;; (def e (child-with-tag a :entity #(= "dwellings" (-> % :attrs :name))))
;; (order-by-clause e "" true)


(defn insert-query
  "Generate an appropriate `insert` query for this `entity`.
  TODO: this depends on the idea that system-unique properties
  are not insertable, which is... dodgy."
  [entity]
  (let [entity-name (safe-name entity :sql)
        pretty-name (singularise entity-name)
        insertable-property-names (map
                                    #(safe-name % :sql)
                                    (insertable-properties entity))
        query-name (str "create-" pretty-name "!")
        signature (if (has-primary-key? entity)
                    ":? :1" ;; bizarrely, if you want to return the keys,
                    ;; you have to use a query signature.
                    ":! :n")]
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
  (let [entity-name (safe-name entity :sql)
        pretty-name (singularise entity-name)
        property-names (map
                         #(-> % :attrs :name)
                         (insertable-properties entity))
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
            (s/join
              ",\n\t"
              (map
                #(str (safe-name % :sql) " = " (keyword %))
                property-names))
            "\n"
            (where-clause entity))})))


(defn search-query [entity application]
  "Generate an appropriate search query for string fields of this `entity`"
  (let [entity-name (safe-name entity :sql)
        pretty-name (singularise entity-name)
        query-name (str "search-strings-" entity-name)
        signature ":? :*"
        properties (remove #(#{"(safe-name entity :sql)"}(:type (:attrs %))) (all-properties entity))]
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
                 "WHERE true"
                 (filter
                   string?
                   (map
                     #(let
                        [sn (safe-name % :sql)]
                        (str
                          "(if (:" (-> % :attrs :name) " params) (str \"AND "
                          (case (-> % :attrs :type)
                            ("string" "text")
                            (str
                              sn
                              " LIKE '%\" (:" (-> % :attrs :name) " params) \"%' ")
                            ("date" "time" "timestamp")
                            (str
                              sn
                              " = ':" (-> % :attrs :name) "'")
                            "entity"
                            (str
                              sn
                              "_expanded LIKE '%\" (:" (-> % :attrs :name) " params) \"%'")
                            (str
                              sn
                              " = :"
                              (-> % :attrs :name)))
                          "\"))"))
                     properties))))
             (order-by-clause entity "lv_" true)
             "--~ (if (:offset params) \"OFFSET :offset \")"
             "--~ (if (:limit params) \"LIMIT :limit\" \"LIMIT 100\")")))})))

;; (search-query e a)


(defn select-query
  "Generate an appropriate `select` query for this `entity`"
  ([entity properties]
   (if-not
     (empty? properties)
     (let [entity-name (safe-name entity :sql)
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
  (let [entity-name (safe-name entity :sql)
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
             (str "SELECT DISTINCT lv_" entity-name ".* FROM lv_" entity-name)
             (order-by-clause entity "lv_" false)
             "--~ (if (:offset params) \"OFFSET :offset \")"
             "--~ (if (:limit params) \"LIMIT :limit\" \"LIMIT 100\")")))})))


(defn foreign-queries
  "Generate any foreign entity queries for this `entity` of this `application`."
  [entity application]
  (let [entity-name (:name (:attrs entity))
        pretty-name (singularise entity-name)
        entity-safe (safe-name entity :sql)
        links (filter #(:entity (:attrs %)) (children-with-tag entity :property))]
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
               safe-far (safe-name far-entity :sql)
               farkey (-> % :attrs :farkey)
               link-type (-> % :attrs :type)
               link-field (-> % :attrs :name)
               query-name (list-related-query-name % entity far-entity false)
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
                               (str "-- :doc lists all existing " pretty-far " records related to a given " pretty-name)
                               (str "SELECT DISTINCT lv_" entity-safe ".* \nFROM lv_" entity-safe)
                               (str "WHERE lv_" entity-safe "." (safe-name % :sql) " = :id")
                               (order-by-clause entity "lv_" false))
                    "link" (let [ltn
                                 (link-table-name % entity far-entity)]
                             (list
                               (str "-- :name " query-name " " signature)
                               (str "-- :doc links all existing " pretty-far " records related to a given " pretty-name)
                               (str "SELECT DISTINCT lv_" safe-far ".* \nFROM lv_" safe-far ", " ltn)
                               (str "WHERE lv_" safe-far "."
                                    (safe-name (first (key-names far-entity)) :sql)
                                    " = " ltn "." (singularise safe-far) "_id")
                               (str "\tAND " ltn "." (singularise entity-safe) "_id = :id")
                               (order-by-clause far-entity "lv_" false)))
                    "list" (list
                             (str "-- :name " query-name " " signature)
                             (str "-- :doc lists all existing " pretty-far " records related to a given " pretty-name)
                             (str "SELECT DISTINCT lv_" safe-far ".* \nFROM lv_" safe-far)
                             (str "WHERE lv_" safe-far "." (safe-name (first (key-names far-entity)) :sql) " = :id")
                             (order-by-clause far-entity "lv_" false))
                    (list (str "ERROR: unexpected type " link-type " of property " %)))))
              }))
        links))))


(defn delete-query
  "Generate an appropriate `delete` query for this `entity`"
  [entity]
  (if
    (has-primary-key? entity)
    (let [entity-name (safe-name entity :sql)
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
              "-- :doc deletes an existing " pretty-name " record\n"
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
    (do-or-warn
      (do
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
                :query
                (sort
                  #(compare (:name %1) (:name %2))
                  (vals
                    (queries application)))))))
        (if (pos? *verbosity*)
          (*warn* (str "\tGenerated " filepath)))))))


(defn generate-documentation
  "Generate, as a string, appropriate documentation for a function wrapping this `query` map."
  [query]
  (let [v (volatility (:entity query))]
    (s/join
      " "
      (list
        (case
          (:type query)
          :delete-1
          (str "delete one record from the `"
               (-> query :entity :attrs :name)
               "` table. Expects the following key(s) to be present in `params`: `"
               (-> query :entity key-names)
               "`.")
          :insert-1
          (str "insert one record to the `"
               (-> query :entity :attrs :name)
               "` table. Expects the following key(s) to be present in `params`: `"
               (pr-str
                 (map
                   #(keyword (:name (:attrs %)))
                   (-> query :entity insertable-properties )))
               "`. Returns a map containing the keys `"
               (-> query :entity key-names)
               "` identifying the record created.")
          :select-1
          (str "select one record from the `"
               (-> query :entity :attrs :name)
               "` table. Expects the following key(s) to be present in `params`: `"
               (-> query :entity key-names)
               "`. Returns a map containing the following keys: `"
               (map #(keyword (:name (:attrs %))) (-> query :entity all-properties))
               "`.")
          :select-many
          (str "select all records from the `"
               (-> query :entity :attrs :name)
               "` table. If the keys `(:limit :offset)` are present in the request then they will be used to page through the data. Returns a sequence of maps each containing the following keys: `"
               (pr-str
                 (map
                   #(keyword (:name (:attrs %)))
                   (-> query :entity all-properties)))
               "`.")
          :text-search
          (str "select all records from the `"
               (-> query :entity :attrs :name)
               ;; TODO: this doc-string is out of date
               "` table with any text field matching the value of the key `:pattern` which should be in the request. If the keys `(:limit :offset)` are present in the request then they will be used to page through the data. Returns a sequence of maps each containing the following keys: `"
               (pr-str
                 (map
                   #(keyword (:name (:attrs %)))
                   (-> query :entity all-properties)))
               "`.")
          :update-1
          (str "update one record in the `"
               (-> query :entity :attrs :name)
               "` table. Expects the following key(s) to be present in `params`: `"
               (pr-str
                 (distinct
                   (sort
                     (map
                       #(keyword (:name (:attrs %)))
                       (flatten
                         (cons
                           (-> query :entity key-properties)
                           (-> query :entity insertable-properties)))))))
               "`."))
        (if-not
          (zero? v)
          (str "Results will be held in cache for " v " seconds."))))))
