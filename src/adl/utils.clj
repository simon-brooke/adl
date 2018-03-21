(ns adl.utils
  (:require [clojure.string :as s]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; adl.utils: utility functions generally useful to generators.
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

;;; **Argument name conventions**: arguments with names of the form `*-map`
;;; represent elements extracted from an ADL XML file as parsed by
;;; `clojure.xml/parse`. Thus `entity-map` represents an ADL entity,
;;; `property-map` a property, and so on.
;;;
;;; Generally, `(:tag x-map) => "x"`, and for every such object
;;; `(:attrs x-map)` should return a map of attributes whose keys
;;; are keywords and whose values are strings.

(defn singularise
  "Assuming this string represents an English language plural noun,
  construct a Clojure symbol name which represents the singular."
  [string]
  (s/replace (s/replace (s/replace string #"_" "-") #"s$" "") #"ie$" "y"))

(defn entities
  [application-map]
  (filter #(= (-> % :tag) :entity) (:content application-map)))

(defn is-link-table?
  "Does this `entity-map` represent a pure link table?"
  [entity-map]
  (let [properties (-> entity-map :content :properties vals)
        links (filter #(-> % :attrs :entity) properties)]
    (= (count properties) (count links))))


(defn key-properties
  "Return a list of all properties in the primary key of this `entity-map`."
  [entity-map]
  (filter
   #(= (:tag %) :property)
   (:content
    ;; there's required to be only one key element in and entity element
    (first
     (filter
      #(= (:tag %) :key)
      (:content entity-map))))))


(defn insertable-key-properties
  "List properties in the key of the entity indicated by this `entity-map`
  which should be inserted.
  A key property is insertable it it is not `system` (database) generated.
  But note that `system` is the default."
  [entity-map]
  (filter
   #(let
      [generator (-> % :attrs :generator)]
      (not
       (or (nil? generator)
           (= generator "system"))))
      (key-properties entity-map)))


(defn key-names
  "List the names of all properties in the primary key of this `entity-map`."
  [entity-map]
  (remove
    nil?
    (map
      #(:name (:attrs %))
      (key-properties entity-map))))


(defn has-primary-key?
  "True if this `entity-map` has a primary key."
  [entity-map]
  (not (empty? (key-names entity-map))))


(defn properties
  "List the non-primary-key properties of this `entity-map`."
  [entity-map]
  (filter #(= (-> % :tag) :property) (:content entity-map)))


(defn has-non-key-properties?
  "True if this `entity-map` has properties which do not form part of the
  primary key."
  [entity-map]
  (not
   (empty? (properties entity-map))))


(defn property-names
  "List the names of non-primary-key properties of this `entity-map`."
  [entity-map]
  (map #(:name (:attrs %)) (properties entity-map)))


(defn quoted-type?
  "Is the type of the property represented by this `property-map` one whose
  values should be quoted in SQL queries?
  TODO: this won't work for typedef types, which means we need to pass the
  entire parsed ADL down the chain to here (and probably, generally) so that
  we can resolve issues like that."
  [property-map]
  (#{"string", "text", "date", "time", "timestamp"} (-> property-map :attrs :type)))

