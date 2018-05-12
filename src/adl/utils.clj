(ns ^{:doc "Application Description Language - utility functions."
      :author "Simon Brooke"}
  adl.utils
  (:require [clojure.string :as s]
            [clojure.xml :as x]
            [adl.validator :refer [valid-adl? validate-adl]]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; adl.utils: utility functions.
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


(defn children
  "Return the children of this `element`; if `predicate` is passed, return only those
  children satisfying the predicate."
  ([element]
   (if
     (keyword? (:tag element)) ;; it has a tag; it seems to be an XML element
     (:content element)))
  ([element predicate]
     (remove ;; there's a more idionatic way of doing remove-nil-map, but for the moment I can't recall it.
       nil?
       (map
         #(if (predicate %) %)
         (children element)))))


(defn attributes
  "Return the attributes of this `element`; if `predicate` is passed, return only those
  attributes satisfying the predicate."
  ([element]
   (if
     (keyword? (:tag element)) ;; it has a tag; it seems to be an XML element
     (:attrs element)))
  ([element predicate]
     (remove ;; there's a more idionatic way of doing remove-nil-map, but for the moment I can't recall it.
       nil?
       (map
         #(if (predicate %) %)
         (:attrs element)))))


(defn permissions
  "Return appropriate permissions of this `property`, taken from this `entity` of this
  `application`."
  [property entity application]
  (or
    (children property #(= (:tag %) :permission))
    (children entity :permission)))


(defn visible?
  "Return `true` if this property is not `system`-distinct, and is readable
  to the `public` group; else return a list of groups to which it is readable,
  given these `permissions`."
  [property permissions]
  (let [attributes (attributes property)]
    (if
      (not
        (and
          ;; if it's immutable and system distinct, the user should not need to see it.
          (= (:immutable attributes) "true")
          (= (:distinct attributes) "system")))
      (map
        #(if
           (some #{"read" "insert" "noedit" "edit" "all"} (:permission (:attrs %)))
           (:group (:attrs %)))
        permissions))))


(defn singularise [string]
  (s/replace (s/replace (s/replace string #"_" "-") #"s$" "") #"ie$" "y"))


(defn link-table?
  "Return true if this `entity` represents a link table."
  [entity]
  (let [properties (children entity #(= (:tag %) :property))
        links (filter #(-> % :attrs :entity) properties)]
    (= (count properties) (count links))))

(defn read-adl [url]
  (let [adl (x/parse url)
        valid? (valid-adl? adl)]
    adl))
;;     (if valid? adl
;;       (throw (Exception. (str (validate-adl adl)))))))

(defn key-names [entity-map]
  (remove
    nil?
    (map
      #(:name (:attrs %))
      (vals (:content (:key (:content entity-map)))))))


(defn has-primary-key? [entity-map]
  (> (count (key-names entity-map)) 0))


(defn has-non-key-properties? [entity-map]
  (>
    (count (vals (:properties (:content entity-map))))
    (count (key-names entity-map))))




;; (read-adl "../youyesyet/stripped.adl.xml")
