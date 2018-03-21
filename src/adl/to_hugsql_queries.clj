(ns ^{:doc "Application Description Language: generate HUGSQL queries file."
      :author "Simon Brooke"}
  adl.to-hugsql-queries
  (:require [clojure.java.io :refer [file]]
            [clojure.math.combinatorics :refer [combinations]]
            [clojure.string :as s]
            [clj-time.core :as t]
            [clj-time.format :as f]
            [adl.utils :refer [singularise is-link-table?]]))

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


(defn key-names [entity-map]
  (let [k (first (filter #(= (:tag %) :key) (:content entity-map)))]
  (remove
    nil?
    (map
      #(:name (:attrs %))
      (filter #(= (:tag %) :property) (:content k))))))


(defn has-primary-key? [entity-map]
  (not (empty? (key-names entity-map))))


(defn has-non-key-properties? [entity-map]
  (not
   (empty? (filter #(= (:tag %) :property) (:content entity-map)))))


(defn where-clause [entity-map]
  (let
    [entity-name (:name (:attrs entity-map))]
    (str
      "WHERE " entity-name "."
      (s/join
        (str " AND\n\t" entity-name ".")
        (map #(str % " = " (keyword %)) (key-names entity-map))))))


(defn order-by-clause [entity-map]
  (let
    [entity-name (:name (:attrs entity-map))
     preferred (map
                #(:name (:attrs %))
                (filter #(and
                          (= (-> % :attrs :distinct) "user")
                          (= (-> % :tag) :property))
                        (-> entity-map :content)))]
    (str
     "ORDER BY " entity-name "."
     (s/join
      (str ",\n\t" entity-name ".")
      (doall (flatten (cons preferred (key-names entity-map))))))))

(defn property-names [entity-map]
  (map #(:name (:attrs %)) (filter #(= (-> % :tag) :property) (:content entity-map))))

(defn insert-query [entity-map]
  (let [entity-name (:name (:attrs entity-map))
        pretty-name (singularise entity-name)
        all-property-names (property-names entity-map)
        query-name (str "create-" pretty-name "!")
        signature ":! :n"]
    (hash-map
      (keyword query-name)
      {:name query-name
       :signature signature
       :entity entity-map
       :type :insert-1
       :query
       (str "-- :name " query-name " " signature "\n"
            "-- :doc creates a new " pretty-name " record\n"
            "INSERT INTO " entity-name " ("
            (s/join ",\n\t" all-property-names)
            ")\nVALUES ("
            (s/join ",\n\t" (map keyword all-property-names))
            ")"
            (if
              (has-primary-key? entity-map)
              (str "\nreturning " (s/join ",\n\t" (key-names entity-map))))
            "\n\n")})))


(defn update-query [entity-map]
  (if
    (and
      (has-primary-key? entity-map)
      (has-non-key-properties? entity-map))
    (let [entity-name (:name (:attrs entity-map))
          pretty-name (singularise entity-name)
          property-names (property-names entity-map)
          query-name (str "update-" pretty-name "!")
          signature ":! :n"]
      (hash-map
        (keyword query-name)
        {:name query-name
         :signature signature
         :entity entity-map
         :type :update-1
         :query
         (str "-- :name " query-name " " signature "\n"
              "-- :doc updates an existing " pretty-name " record\n"
              "UPDATE " entity-name "\n"
              "SET "
              (s/join ",\n\t" (map #(str % " = " (keyword %)) property-names))
              "\n"
              (where-clause entity-map)
              "\n\n")}))
    {}))


(defn search-query [entity-map]
  (let [entity-name (:name (:attrs entity-map))
        pretty-name (singularise entity-name)
        query-name (str "search-strings-" pretty-name)
        signature ":? :1"
        string-fields (filter
                       #(and
                         (= (-> % :attrs :type) "string")
                         (= (:tag %) :property))
                       (-> entity-map :content))]
    (if
      (empty? string-fields)
      {}
      (hash-map
       (keyword query-name)
       {:name query-name
        :signature signature
        :entity entity-map
        :type :text-search
        :query
        (str "-- :name " query-name " " signature "\n"
             "-- :doc selects existing " entity-name " records having any string field matching `:pattern` by substring match\n"
             "SELECT * FROM " entity-name "\n"
             "WHERE "
             (s/join
              "\n\tOR "
              (map
               #(str (-> % :attrs :name) " LIKE '%:pattern%'")
               string-fields))
             "\n"
             (order-by-clause entity-map)
             "\n"
            "--~ (if (:offset params) \"OFFSET :offset \") \n"
            "--~ (if (:limit params) \"LIMIT :limit\" \"LIMIT 100\")"
             "\n\n")}))))


(defn select-query [entity-map]
  (if
    (has-primary-key? entity-map)
    (let [entity-name (:name (:attrs entity-map))
          pretty-name (singularise entity-name)
          query-name (str "get-" pretty-name)
          signature ":? :1"]
      (hash-map
        (keyword query-name)
        {:name query-name
         :signature signature
         :entity entity-map
         :type :select-1
         :query
         (str "-- :name " query-name " " signature "\n"
              "-- :doc selects an existing " pretty-name " record\n"
              "SELECT * FROM " entity-name "\n"
              (where-clause entity-map)
              "\n\n")}))
    {}))


(defn list-query
  "Generate a query to list records in the table represented by this `entity-map`.
  Parameters `:limit` and `:offset` may be supplied. If not present limit defaults
  to 100 and offset to 0."
  [entity-map]
  (let [entity-name (:name (:attrs entity-map))
        pretty-name (singularise entity-name)
        query-name (str "list-" entity-name)
        signature ":? :*"]
    (hash-map
      (keyword query-name)
      {:name query-name
       :signature signature
       :entity entity-map
       :type :select-many
       :query
       (str "-- :name " query-name " " signature "\n"
            "-- :doc lists all existing " pretty-name " records\n"
            "SELECT * FROM " entity-name "\n"
            (order-by-clause entity-map) "\n"
            "--~ (if (:offset params) \"OFFSET :offset \") \n"
            "--~ (if (:limit params) \"LIMIT :limit\" \"LIMIT 100\")"
            "\n\n")})))


(defn foreign-queries [entity-map entities-map]
  (let [entity-name (:name (:attrs entity-map))
        pretty-name (singularise entity-name)
        links (filter #(-> % :attrs :entity) (-> entity-map :content :properties vals))]
    (apply
      merge
      (map
        #(let [far-name (-> % :attrs :entity)
               far-entity ((keyword far-name) entities-map)
               pretty-far (s/replace (s/replace far-name #"_" "-") #"s$" "")
               farkey (-> % :attrs :farkey)
               link-field (-> % :attrs :name)
               query-name (str "list-" entity-name "-by-" pretty-far)
               signature ":? :*"]
           (hash-map
             (keyword query-name)
             {:name query-name
              :signature signature
              :entity entity-map
              :type :select-one-to-many
              :far-entity far-entity
              :query
              (str "-- :name " query-name " " signature "\n"
                   "-- :doc lists all existing " pretty-name " records related to a given " pretty-far "\n"
                   "SELECT * \nFROM " entity-name "\n"
                   "WHERE " entity-name "." link-field " = :id\n"
                   (order-by-clause entity-map)
                   "\n\n")}))
        links))))


(defn link-table-query [near link far]
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
       (str "-- :name " query-name " " signature " \n"
            "-- :doc lists all existing " near-name " records related through " link-name " to a given " pretty-far "\n"
            "SELECT "near-name ".*\n"
            "FROM " near-name ", " link-name "\n"
            "WHERE " near-name "." (first (key-names near)) " = " link-name "." (-> (links (keyword near-name)) :attrs :name) "\n\t"
            "AND " link-name "." (-> (links (keyword far-name)) :attrs :name) " = :id\n"
            (order-by-clause near)
            "\n\n")})))


(defn link-table-queries [entity-map entities-map]
  (let
    [entities (map
                #((keyword %) entities-map)
                (remove nil? (map #(-> % :attrs :entity) (-> entity-map :content :properties vals))))
     pairs (combinations entities 2)]
    (apply
      merge
      (map
        #(merge
           (link-table-query (nth % 0) entity-map (nth % 1))
           (link-table-query (nth % 1) entity-map (nth % 0)))
        pairs))))



(defn delete-query [entity-map]
  (if
    (has-primary-key? entity-map)
    (let [entity-name (:name (:attrs entity-map))
          pretty-name (singularise entity-name)
          query-name (str "delete-" pretty-name "!")
          signature ":! :n"]
      (hash-map
        (keyword query-name)
        {:name query-name
         :signature signature
         :entity entity-map
         :type :delete-1
         :query
         (str "-- :name " query-name " " signature "\n"
              "-- :doc updates an existing " pretty-name " record\n"
              "DELETE FROM " entity-name "\n"
              (where-clause entity-map)
              "\n\n")}))))


(defn queries
  [entity-map entities-map]
  (merge
    {}
    (insert-query entity-map)
    (update-query entity-map)
    (delete-query entity-map)
    (if
      (is-link-table? entity-map)
      (link-table-queries entity-map entities-map)
      (merge
        (select-query entity-map)
        (list-query entity-map)
        (search-query entity-map)
        (foreign-queries entity-map entities-map)))))


;; (defn migrations-to-queries-sql
;;   ([migrations-path]
;;    (migrations-to-queries-sql migrations-path "queries.auto.sql"))
;;   ([migrations-path output]
;;    (let
;;      [adl-struct (migrations-to-xml migrations-path "Ignored")
;;       file-content (apply
;;                     str
;;                     (cons
;;                      (str "-- "
;;                           output
;;                           " autogenerated by \n-- [squirrel-parse](https://github.com/simon-brooke/squirrel-parse)\n-- at "
;;                           (f/unparse (f/formatters :basic-date-time) (t/now))
;;                           "\n\n")
;;                      (doall
;;                       (map
;;                        #(:query %)
;;                        (sort
;;                         #(compare (:name %1) (:name %2))
;;                         (vals
;;                          (apply
;;                           merge
;;                           (map
;;                            #(queries % adl-struct)
;;                            (vals adl-struct)))))))))]
;;      (spit output file-content)
;;      file-content)))
