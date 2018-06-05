(ns ^{;; :doc "Application Description Language - generate RING routes for REST requests."
      :author "Simon Brooke"}
  adl.to-selmer-templates
  (:require [adl.utils :refer :all]
            [clojure.java.io :refer [file]]
            [clojure.math.combinatorics :refer [combinations]]
            [clojure.pprint :as p]
            [clojure.string :as s]
            [clojure.xml :as x]
            [clj-time.core :as t]
            [clj-time.format :as f]
            [hiccup.core :as h]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; adl.to-json-routes: generate RING routes for REST requests.
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

(defn file-header
  "Generate a header for a template file."
  [filename]
  (str
    "{% extends \"templates/base.html\" %}\n\n"
    "<!-- File "
    filename
    " generated "
    (t/now)
    " by adl.to-selmer-templates.\n"
    "See [Application Description Language](https://github.com/simon-brooke/adl)."
    "-->\n\n"
    "{% block content %}"))

(defn file-footer
  "Generate a header for a template file."
  [filename]
  "{% endblock %}\n")


(defn prompt
  "Return an appropriate prompt for the given `field-or-property` taken from this
  `form` of this `entity` of this `application`, in the context of the current
  binding of `*locale*`. TODO: something more sophisticated about i18n"
  [field-or-property form entity application]
  (or
    (first
      (children
        field-or-property
        #(and
           (= (:tag %) :prompt)
           (= (:locale :attrs %) *locale*))))
    (:name (:attrs field-or-property))))


(defn csrf-widget
  "For the present, just return the standard cross site scripting protection field statement"
  []
  "{% csrf-field %}")


(defn save-widget
  "Return an appropriate 'save' widget for this `form` operating on this `entity` taken
  from this `application`."
  [form entity application]
  {:tag :p
   :attrs {:class "widget action-safe"}
   :content [{:tag :label
              :attrs {:for "save-button" :class "action-safe"}
              :content [(str "To save this " (:name (:attrs entity)) " record")]}
             {:tag :input
              :attrs {:id "save-button"
                      :name "save-button"
                      :class "action-safe"
                      :type :submit
                      :value (str "Save!")}}]})


(defn delete-widget
  "Return an appropriate 'save' widget for this `form` operating on this `entity` taken
  from this `application`."
  [form entity application]
  {:tag :p
   :attrs {:class "widget action-dangerous"}
   :content [{:tag :label
              :attrs {:for "delete-button" :class "action-dangerous"}
              :content [(str "To delete this " (:name (:attrs entity)) " record")]}
             {:tag :input
              :attrs {:id "delete-button"
                      :name "delete-button"
                      :class "action-dangerous"
                      :type :submit
                      :value (str "Delete!")}}]})


(defn get-options
  "Produce template code to get options for this `property` of this `entity` taken from
  this `application`."
  [property form entity application]
  (let
    [type (:type (:attrs property))
     farname (:entity (:attrs property))
     farside (first
               (children
                 application
                 #(and
                    (= (:tag %) :entity)
                    (= (:name (:attrs %)) farname))))
     fs-distinct (flatten
                   (list
                     (children farside #(#{"user" "all"} (:distinct (:attrs %))))
                     (children
                       (first
                         (children farside #(= (:tag %) :key)))
                       #(#{"user" "all"} (:distinct (:attrs %))))))
     farkey (or
              (:farkey (:attrs property))
              (:name (:attrs (first (children (children farside #(= (:tag %) :key))))))
              "id")]
    [(str "{% for record in " farname " %}<option value='{{record." farkey "}}'>"
         (s/join " " (map #(str "{{record." (:name (:attrs %)) "}}") fs-distinct))
         "</option>{% endfor %}")]))


(defn widget-type
  "Return an appropriate HTML5 input type for this property."
  ([property application]
   (widget-type property application (typedef property application)))
  ([property application typedef]
   (let [t (if
             typedef
             (:type (:attrs typedef))
             (:type (:attrs property)))]
     (case t
       ("integer" "real" "money") "number"
       ("uploadable" "image") "file"
       "boolean" "checkbox"
       "date" "date"
       "time" "time"
       "text" ;; default
       ))))


(defn widget
  "Generate a widget for this `field-or-property` of this `form` for this `entity`
  taken from within this `application`."
  [field-or-property form entity application]
  (let
    [widget-name (:name (:attrs field-or-property))
     property (if
                (= (:tag field-or-property) :property)
                field-or-property
                (first
                  (children
                    entity
                    #(and
                       (= (:tag %) :property)
                       (= (:name (:attrs %)) (:property (:attrs field-or-property)))))))
     permissions (permissions property form entity application)
     typedef (typedef property application)
     visible-to (visible-to permissions)
     ;; if the form isn't actually a form, no widget is writable.
     writable-by (if (= (:tag form) :form) (writable-by permissions))
     select? (#{"entity" "list" "link"} (:type (:attrs property)))]
    (if
      (formal-primary-key? property entity)
      {:tag :input
       :attrs {:id widget-name
               :name widget-name
               :type "hidden"
               :value (str "{{record." widget-name "}}")}}
      {:tag :p
       :attrs {:class "widget"}
       :content [{:tag :label
                  :attrs {:for widget-name}
                  :content [(prompt field-or-property form entity application)]}
                 "TODO: selmer command to hide for all groups except for those for which it is writable"
                 (if
                   select?
                   {:tag :select
                    :attrs {:id widget-name
                            :name widget-name}
                    :content (get-options property form entity application)}
                   {:tag :input
                    :attrs (merge
                             {:id widget-name
                              :name widget-name
                              :type (widget-type property application typedef)
                              :value (str "{{record." widget-name "}}")}
                             (if
                               (:minimum (:attrs typedef))
                               {:min (:minimum (:attrs typedef))})
                             (if
                               (:maximum (:attrs typedef))
                               {:max (:maximum (:attrs typedef))}))})
                 "{% else %}"
                 "TODO: selmer if command to hide for all groups except to those for which it is readable"
                 {:tag :span
                  :attrs {:id widget-name
                          :name widget-name
                          :class "pseudo-widget disabled"}
                  :content [(str "{{record." widget-name "}}")]}
                 "{% endif %}"
                 "{% endif %}"]})))


(defn form-to-template
  "Generate a template as specified by this `form` element for this `entity`,
  taken from this `application`. If `form` is nill, generate a default form
  template for the entity."
  [form entity application]
  (let
    [name (str (if form (:name (:attrs form)) "edit") "-" (:name (:attrs entity)))
     keyfields (children
                 ;; there should only be one key; its keys are properties
                 (first (children entity #(= (:tag %) :key))))
     fields (if
              (and form (= "listed" (:properties (:attrs form))))
              ;; if we've got a form, collect its fields, fieldgroups and verbs
              (flatten
                (map #(if (#{:field :fieldgroup :verb} (:tag %)) %)
                     (children form)))
              (children entity #(= (:tag %) :property)))]
    {:tag :div
     :attrs {:id "content" :class "edit"}
     :content
     [{:tag :form
       :attrs {:action (str "{{servlet-context}}/" name)
               :method "POST"}
       :content (flatten
                  (list
                    (csrf-widget)
                    (map
                      #(widget % form entity application)
                      keyfields)
                    (map
                      #(widget % form entity application)
                      fields)
                    (save-widget form entity application)
                    (delete-widget form entity application)))}]}))



(defn page-to-template
  "Generate a template as specified by this `page` element for this `entity`,
  taken from this `application`. If `page` is nill, generate a default page
  template for the entity."
  [page entity application]
  )

(defn list-to-template
  "Generate a template as specified by this `list` element for this `entity`,
  taken from this `application`. If `list` is nill, generate a default list
  template for the entity."
  [list-spec entity application]
  (let [user-distinct-fields]
    [:tag :div
     :attrs {:id "content" :class "edit"}
     :content
     [:table {:caption (:name (:attrs entity))}
      [:thead
       [:tr
        (map
         #(vector :th (prompt %))
         (:fields list-spec))]
       [tr
        (map
         #(vector :th (prompt %))
         (:fields list-spec))]
        ]
        "{% for record in %records% %}"
        [:tr
          (map
           (fn [field]
             [:td (str "{% record." (:name (:attrs %)) " %}")])
           (:fields list-spec))
         [:td
          [:a
           {:href
            (str
             "view-or-edit-"
             (:name (:attrs entity))
             "?"
             (s/join
              "&amp;"
              (map
               #(let [n (:name (:attrs %))]
                  (str n "=record." n)))
              (children (first (filter #(= (:tag %) :key) (children entity))))))}
           View]]]
      "{% endfor %}"
      [:tfoot]]
     "{% if offset > 0 %}"
     [:div {:id "back-link-container"}
      [:a {:href "FIXME"}
       Previous]]
     "{% endif %}"
     [:div {:id "big-link-container"}
      [:a {:href "FIXME"}
       Next]]
     ]))






        ]}))



(defn entity-to-templates
  "Generate one or more templates for editing instances of this
  `entity` in this `application`"
  [entity application]
  (let
    [forms (children entity #(= (:tag %) :form))
     pages (children entity #(= (:tag %) :page))
     lists (children entity #(= (:tag %) :list))]
    (if
      (and
        (= (:tag entity) :entity) ;; it seems to be an ADL entity
        (not (link-table? entity)))
      (merge
        (if
          forms
          (apply merge (map #(assoc {} (keyword (str "form-" (:name (:attrs entity)) "-" (:name (:attrs %))))
                               (form-to-template % entity application))
                            forms))
          {(keyword (str "form-" (:name (:attrs entity))))
           (form-to-template nil entity application)})
        (if
          pages
          (apply merge (map #(assoc {} (keyword (str "page-" (:name (:attrs entity)) "-" (:name (:attrs %))))
                               (page-to-template % entity application))
                            pages))
          {(keyword (str "page-" (:name (:attrs entity))))
           (page-to-template nil entity application)})
        (if
          lists
          (apply merge (map #(assoc {} (keyword (str "list-" (:name (:attrs entity)) "-" (:name (:attrs %))))
                               (list-to-template % entity application))
                            lists))
          {(keyword (str "list-" (:name (:attrs entity))))
           (form-to-template nil entity application)})))))


(defn write-template-file
  [filename template]
  (spit
    (str *output-path* filename)
    (s/join
      "\n"
      (list
        (file-header filename)
        (with-out-str (x/emit-element template))
        (file-footer filename)))))


(defn to-selmer-templates
  "Generate all [Selmer](https://github.com/yogthos/Selmer) templates implied by this ADL `application` spec."
  [application]
  (let
    [templates-map (reduce
                     merge
                     {}
                     (map
                       #(entity-to-templates % application)
                       (children application #(= (:tag %) :entity))))]
    (doall
      (map
        #(if
           (templates-map %)
           (let [filename (str (name %) ".html")]
             (write-template-file filename (templates-map %))))
        (keys templates-map)))
    templates-map))


