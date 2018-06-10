(ns ^{:doc "Application Description Language - generate HUGSQL queries file."
      :author "Simon Brooke"}
  adl.to-hugsql-queries
  (:require [clojure.java.io :refer [file]]
            [clojure.math.combinatorics :refer [combinations]]
            [clojure.string :as s]
            [clj-time.core :as t]
            [clj-time.format :as f]
            [adl.utils :refer :all]))

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


(def ^:dynamic *output-path*
  "The path to which generated files will be written."
  "resources/auto/")

(def electors {:tag :entity, :attrs {:magnitude "6", :name "electors", :table "electors"}, :content [{:tag :key, :attrs nil, :content [{:tag :property, :attrs {:distinct "system", :immutable "true", :column "id", :name "id", :type "integer", :required "true"}, :content [{:tag :prompt, :attrs {:locale "en-GB", :prompt "id"}, :content nil}]}]} {:tag :property, :attrs {:distinct "user", :column "name", :name "name", :type "string", :required "true", :size "64"}, :content [{:tag :prompt, :attrs {:locale "en-GB", :prompt "name"}, :content nil}]} {:tag :property, :attrs {:farkey "id", :entity "dwelling", :column "dwelling_id", :name "dwelling_id", :type "entity", :required "true"}, :content [{:tag :prompt, :attrs {:locale "en-GB", :prompt "Flat"}, :content nil}]} {:tag :property, :attrs {:distinct "user", :column "phone", :name "phone", :type "string", :size "16"}, :content [{:tag :prompt, :attrs {:locale "en-GB", :prompt "phone"}, :content nil}]} {:tag :property, :attrs {:distinct "user", :column "email", :name "email", :type "string", :size "128"}, :content [{:tag :prompt, :attrs {:locale "en-GB", :prompt "email"}, :content nil}]} {:tag :property, :attrs {:default "Unknown", :farkey "id", :entity "genders", :column "gender", :type "entity", :name "gender"}, :content [{:tag :prompt, :attrs {:locale "en-GB", :prompt "gender"}, :content nil}]} {:tag :list, :attrs {:name "Electors", :properties "listed"}, :content [{:tag :field, :attrs {:property "id"}, :content nil} {:tag :field, :attrs {:property "name"}, :content nil} {:tag :field, :attrs {:property "dwelling_id"}, :content nil} {:tag :field, :attrs {:property "phone"}, :content nil} {:tag :field, :attrs {:property "email"}, :content nil} {:tag :field, :attrs {:property "gender"}, :content nil}]} {:tag :form, :attrs {:name "Elector", :properties "listed"}, :content [{:tag :field, :attrs {:property "id"}, :content nil} {:tag :field, :attrs {:property "name"}, :content nil} {:tag :field, :attrs {:property "dwelling_id"}, :content nil} {:tag :field, :attrs {:property "phone"}, :content nil} {:tag :field, :attrs {:property "email"}, :content nil} {:tag :field, :attrs {:property "gender"}, :content nil}]}]})

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
  [entity]
  (let
    [entity-name (:name (:attrs entity))
     preferred (map
                 #(:name (:attrs %))
                 (filter #(#{"user" "all"} (-> % :attrs :distinct))
                         (children entity #(= (:tag %) :property))))]
    (if
      (empty? preferred)
      ""
      (str
        "ORDER BY " entity-name "."
        (s/join
          (str ",\n\t" entity-name ".")
          (flatten (cons preferred (key-names entity))))))))


(defn insert-query
  "Generate an appropriate `insert` query for this `entity`.
  TODO: this depends on the idea that system-unique properties
  are not insertable, which is... dodgy."
  [entity]
  (let [entity-name (:name (:attrs entity))
        pretty-name (singularise entity-name)
        insertable-property-names (map #(:name (:attrs %)) (insertable-properties entity))
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
              (str "\nreturning " (s/join ",\n\t" (key-names entity)))))})))


(defn update-query
  "Generate an appropriate `update` query for this `entity`"
  [entity]
  (if
    (and
      (has-primary-key? entity)
      (has-non-key-properties? entity))
    (let [entity-name (:name (:attrs entity))
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
              (s/join ",\n\t" (map #(str % " = " (keyword %)) property-names))
              "\n"
              (where-clause entity))}))
    {}))


(defn search-query [entity]
  "Generate an appropriate search query for string fields of this `entity`"
  (let [entity-name (:name (:attrs entity))
        pretty-name (singularise entity-name)
        query-name (str "search-strings-" pretty-name)
        signature ":? :1"
        properties (all-properties entity)]
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
               " records having any string field matching `:pattern` by substring match")
             (str "SELECT * FROM " entity-name)
             "WHERE "
             (s/join
               "\n\tOR "
               (filter
                 string?
                 (map
                   #(if
                      (#{"string" "date" "text"} (:type (:attrs %)))
                      (str (-> % :attrs :name) " LIKE '%:pattern%'"))
                   properties)))
             (order-by-clause entity)
             "--~ (if (:offset params) \"OFFSET :offset \")"
             "--~ (if (:limit params) \"LIMIT :limit\" \"LIMIT 100\")")))})))


(defn select-query
  "Generate an appropriate `select` query for this `entity`"
  ([entity properties]
   (if
     (not (empty? properties))
     (let [entity-name (:name (:attrs entity))
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

(select-query electors)


(defn list-query
  "Generate a query to list records in the table represented by this `entity`.
  Parameters `:limit` and `:offset` may be supplied. If not present limit defaults
  to 100 and offset to 0."
  [entity]
  (let [entity-name (:name (:attrs entity))
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
             (str "SELECT * FROM " entity-name)
             (order-by-clause entity)
             "--~ (if (:offset params) \"OFFSET :offset \")"
             "--~ (if (:limit params) \"LIMIT :limit\" \"LIMIT 100\")")))})))


(defn foreign-queries

  [entity application]
  (let [entity-name (:name (:attrs entity))
        pretty-name (singularise entity-name)
        links (filter #(-> % :attrs :entity) (children entity #(= (:tag %) :property)))]
    (apply
      merge
      (map
        #(let [far-name (-> % :attrs :entity)
               far-entity (first
                            (children
                              application
                              (fn [x]
                                (and
                                  (= (:tag x) :entity)
                                  (= (:name (:attrs x)) far-name)))))
               pretty-far (singularise far-name)
               farkey (-> % :attrs :farkey)
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
                  (list
                    (str "-- :name " query-name " " signature)
                    (str "-- :doc lists all existing " pretty-name " records related to a given " pretty-far)
                    (str "SELECT * \nFROM " entity-name)
                    (str "WHERE " entity-name "." link-field " = :id")
                    (order-by-clause entity))))}))
        links))))


(defn link-table-query
  "Generate a query which links across the entity passed as `link`
  from the entity passed as `near` to the entity passed as `far`.
  TODO: not working?"
  [near link far]
  (if
    (and
      (entity? near)
      (entity? link)
      (entity? far))
    (let [properties (-> link :content :properties vals)
          links (apply
                  merge
                  (map
                    #(hash-map (keyword (-> % :attrs :entity)) %)
                    (filter #(-> % :attrs :entity) properties)))
          near-name (-> near :attrs :name)
          link-name (-> link :attrs :name)
          far-name (-> far :attrs :name)
          pretty-far (singularise far-name)
          query-name (str "list-" link-name "-" near-name "-by-" pretty-far)
          signature ":? :*"]
      (hash-map
        (keyword query-name)
        {:name query-name
         :signature signature
         :entity link
         :type :select-many-to-many
         :near-entity near
         :far-entity far
         :query
              (s/join
                "\n"
                (remove
                  empty?
                  (list
         (str "-- :name " query-name " " signature)
              (str "-- :doc lists all existing " near-name " records related through " link-name " to a given " pretty-far )
              (str "SELECT "near-name ".*")
              (str "FROM " near-name ", " link-name )
              (str "WHERE " near-name "." (first (key-names near)) " = " link-name "." (-> (links (keyword near-name)) :attrs :name) )
              ("\tAND " link-name "." (-> (links (keyword far-name)) :attrs :name) " = :id")
              (order-by-clause near))))}))))


(defn link-table-queries [entity application]
  "Generate all the link queries in this `application` which link via this `entity`."
  (let
    [entities (map
                ;; find the far-side entities
                (fn
                  [far-name]
                  (children
                    application
                    (fn [x]
                      (and
                        (= (:tag x) :entity)
                        (= (:name (:attrs x)) far-name)))))
                ;; of those properties of this `entity` which are of type `entity`
                (remove
                  nil?
                  (map
                    #(-> % :attrs :entity)
                    (children entity #(= (:tag %) :property)))))
     pairs (combinations entities 2)]
    (apply
      merge
      (map
        #(merge
           (link-table-query (nth % 0) entity (nth % 1))
           (link-table-query (nth % 1) entity (nth % 0)))
        pairs))))



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
  no entity is specified, generate all queris for the application."
  ([application entity]
   (merge
     {}
     (insert-query entity)
     (update-query entity)
     (delete-query entity)
     (if
       (link-table? entity)
       (link-table-queries entity application)
       {})
     (select-query entity)
     (list-query entity)
     (search-query entity)
     (foreign-queries entity application)))
  ([application]
   (apply
     merge
     (map #(queries application %)
          (children-with-tag application :entity)))))


(defn to-hugsql-queries
  "Generate all [HugSQL](https://www.hugsql.org/) queries implied by this ADL `application` spec."
  [application]
  (spit
    (str *output-path* "queries.sql")
    (s/join
      "\n\n"
      (cons
        (s/join
          "\n-- "
          (list
            "-- File queries.sql"
            "autogenerated by adl.to-hugsql-queries at"
            (t/now)
            "See [Application Description Language](https://github.com/simon-brooke/adl).\n\n"))
          (map
            #(:query %)
            (sort
              #(compare (:name %1) (:name %2))
              (vals
                (queries application))))))))

