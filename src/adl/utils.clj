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


(defn typedef
  "If this `property` is of type `defined`, return its type definition from
  this `application`, else nil."
  [property application]
  (if
    (= (:type (:attrs property)) "defined")
    (first
      (children
        application
        #(and
           (= (:tag %) :typedef)
           (= (:name (:attrs %)) (:typedef (:attrs property))))))))


(defn permissions
  "Return appropriate permissions of this `property`, taken from this `entity` of this
  `application`, in the context of this `page`."
  [property page entity application]
  (first
    (remove
      empty?
      (list
        (children page #(= (:tag %) :permission))
        (children property #(= (:tag %) :permission))
        (children entity #(= (:tag %) :permission))
        (children application #(= (:tag %) :permission))))))


(defn permission-groups
  "Return a list of names of groups to which this `predicate` is true of
  some permission taken from these `permissions`, else nil."
  [permissions predicate]
  (let [groups (remove
                 nil?
                 (map
                   #(if
                      (apply predicate (list %))
                      (:group (:attrs %)))
                   permissions))]
    (if groups groups)))


(defn formal-primary-key?
  "Does this `prop-or-name` appear to be a property (or the name of a property)
  which is a formal primary key of this entity?"
  [prop-or-name entity]
  (if
    (map? prop-or-name)
    (formal-primary-key? (:name (:attrs prop-or-name)) entity)
    (let [primary-key (first (children entity #(= (:tag %) :key)))
          property (first
                     (children
                       primary-key
                       #(and
                          (= (:tag %) :property)
                          (= (:name (:attrs %)) prop-or-name))))]
      (= (:distinct (:attrs property)) "system"))))


(defn visible-to
  "Return a list of names of groups to which are granted read access,
  given these `permissions`, else nil."
  [permissions]
  (permission-groups permissions #(#{"read" "insert" "noedit" "edit" "all"} (:permission (:attrs %)))))


(defn writable-by
  "Return a list of names of groups to which are granted read access,
  given these `permissions`, else nil."
  [permissions]
  (permission-groups permissions #(#{"edit" "all"} (:permission (:attrs %)))))


(defn singularise
  "Attempt to construct an idiomatic English-language singular of this string."
  [string]
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
