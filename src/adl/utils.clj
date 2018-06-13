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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(def ^:dynamic  *locale*
  "The locale for which files will be generated."
  "en-GB")

(def ^:dynamic *output-path*
  "The path to which generated files will be written."
  "resources/auto/")


(defn link-table-name
  "Canonical name of a link table between entity `e1` and entity `e2`."
  [e1 e2]
  (s/join
    "_"
    (cons
      "ln"
      (sort
        (list
          (:name (:attrs e1)) (:name (:attrs e2)))))))


(defn children
  "Return the children of this `element`; if `predicate` is passed, return only those
  children satisfying the predicate."
  ([element]
   (if
     (keyword? (:tag element)) ;; it has a tag; it seems to be an XML element
     (:content element)))
  ([element predicate]
   (filter
     predicate
     (children element))))


(defn child
  "Return the first child of this `element` satisfying this `predicate`."
  [element predicate]
  (first (children element predicate)))


(defn attributes
  "Return the attributes of this `element`; if `predicate` is passed, return only those
  attributes satisfying the predicate."
  ([element]
   (if
     (keyword? (:tag element)) ;; it has a tag; it seems to be an XML element
     (:attrs element)))
  ([element predicate]
   (filter
     predicate
     (attributes element))))


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
  ([property page entity application]
  (first
    (remove
      empty?
      (list
        (children page #(= (:tag %) :permission))
        (children property #(= (:tag %) :permission))
        (children entity #(= (:tag %) :permission))
        (children application #(= (:tag %) :permission))))))
  ([property entity application]
   (permissions property nil entity application))
  ([entity application]
   (permissions nil nil entity application)))


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


(defn entity?
  "Return true if `x` is an ADL entity."
  [x]
  (= (:tag x) :entity))


(defn property?
  "True if `o` is a property."
  [o]
  (= (:tag o) :property))


(defn entity-for-property
  "If this `property` references an entity, return that entity from this `application`"
  [property application]
  (if
    (and (property? property) (:entity (:attrs property)))
    (child
      application
      #(and
         (entity? %)
         (= (:name (:attrs %))(:entity (:attrs property)))))))


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
  (cond
    (.endsWith string "ss") string
    (.endsWith string "ise") string
    true
    (s/replace
      (s/replace
        (s/replace
          (s/replace string #"_" "-")
          #"s$" "")
        #"se$" "s")
      #"ie$" "y")))


(defn capitalise
  "Return a string like `s` but with each token capitalised."
  [s]
  (s/join
    " "
    (map
      #(apply str (cons (Character/toUpperCase (first %)) (rest %)))
      (s/split s #"[ \t\r\n]+"))))


(defn pretty-name
  [entity]
  (capitalise (singularise (:name (:attrs entity)))))



(defn safe-name
  ([string]
    (s/replace string #"[^a-zA-Z0-9-]" ""))
  ([string convention]
   (case convention
     (:sql :c) (s/replace string #"[^a-zA-Z0-9_]" "_")
     :c-sharp (s/replace (capitalise string) #"[^a-zA-Z0-9]" "")
     :java (let
             [camel (s/replace (capitalise string) #"[^a-zA-Z0-9]" "")]
             (apply str (cons (Character/toUpperCase (first camel)) (rest camel))))
     (safe-name string))))


(defn link-table?
  "Return true if this `entity` represents a link table."
  [entity]
  (let [properties (children entity #(= (:tag %) :property))
        links (filter #(-> % :attrs :entity) properties)]
    (= (count properties) (count links))))

(defn read-adl [url]
  (let [adl (x/parse url)
        valid? (valid-adl? adl)]
    (if valid? adl
      (throw (Exception. (str (validate-adl adl)))))))


(defn children-with-tag
  "Return all children of this `element` which have this `tag`;
  if `element` is `nil`, return `nil`."
  [element tag]
  (if
    element
    (children element #(= (:tag %) tag))))

(defn child-with-tag
  "Return the first child of this `element` which has this `tag`;
  if `element` is `nil`, return `nil`."
  [element tag]
  (first (children-with-tag element tag)))

(defmacro properties
  "Return all the properties of this `entity`."
  [entity]
  `(children-with-tag ~entity :property))

(defn descendants-with-tag
  "Return all descendants of this `element`, recursively, which have this `tag`."
  [element tag]
  (flatten
    (remove
      empty?
      (cons
        (children element #(= (:tag %) tag))
        (map
          #(descendants-with-tag % tag)
          (children element))))))


(defn insertable?
  "Return `true` it the value of this `property` may be set from user-supplied data."
  [property]
  (and
    (= (:tag property) :property)
    (not (#{"link"} (:type (:attrs property))))
    (not (= (:distinct (:attrs property)) "system"))))


(defmacro all-properties
  "Return all properties of this `entity` (including key properties)."
  [entity]
  `(descendants-with-tag ~entity :property))


(defn user-distinct-properties
  "Return the properties of this `entity` which are user distinct"
  [entity]
  (filter #(#{"user" "all"} (:distinct (:attrs %))) (all-properties entity)))


(defmacro insertable-properties
  "Return all the properties of this `entity` (including key properties) into
  which user-supplied data can be inserted"
  [entity]
  `(filter
     insertable?
     (all-properties ~entity)))

(defmacro key-properties
  [entity]
  `(children-with-tag (first (children-with-tag ~entity :key)) :property))

(defmacro insertable-key-properties
  [entity]
  `(filter insertable? (key-properties entity)))


(defn key-names [entity]
  (remove
    nil?
    (map
      #(:name (:attrs %))
      (key-properties entity))))


(defn has-primary-key? [entity]
  (> (count (key-names entity)) 0))


(defn has-non-key-properties? [entity]
  (>
    (count (all-properties entity))
    (count (key-properties entity))))


(defn distinct-properties
  [entity]
  (filter
    #(#{"system" "all"} (:distinct (:attrs %)))
    (properties entity)))

(defn path-part
  "Return the URL path part for this `form` of this `entity` within this `application`.
  Note that `form` may be a Clojure XML representation of a `form`, `list` or `page`
  ADL element, or may be one of the keywords `:form`, `:list`, `:page` in which case the
  first child of the `entity` of the specified type will be used."
  [form entity application]
  (cond
    (and (map? form) (#{:list :form :page} (:tag form)))
  (s/join
    "-"
    (flatten
      (list
        (name (:tag form)) (:name (:attrs entity)) (s/split (:name (:attrs form)) #"[ \n\r\t]+"))))
    (keyword? form)
    (path-part (first (children-with-tag entity form)) entity application)))

(defn editor-name
  "Return the path-part of the editor form for this `entity`. Note:
  assumes the editor form is the first form listed for the entity."
  [entity application]
  (path-part :form entity application))

(defn typedef
  [property application]
  (first
    (children application
              #(and
                 (= (:tag %) :typedef)
                 (= (:name (:attrs %))
                    (:definition (:attrs property)))))))

(defn type-for-defined
  [property application]
  (:type (:attrs (typedef property application))))
