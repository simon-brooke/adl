(ns ^{;; :doc "Application Description Language - generate Selmer templates for the HTML pages implied by an ADL file."
      :author "Simon Brooke"}
  adl.to-selmer-templates
  (:require [adl.utils :refer :all]
            [clojure.java.io :refer [file]]
            [clojure.pprint :as p]
            [clojure.string :as s]
            [clojure.xml :as x]
            [clj-time.core :as t]
            [clj-time.format :as f]
            [hiccup.core :as h]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; adl.to-selmer-templates.
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


(defn big-link
  [content url]
  {:tag :div
   :attrs {:class "big-link-container"}
   :content
   [{:tag :a :attrs {:href url}
     :content (if
                (vector? content)
                content
                [content])}]})


(defn back-link
  [content url]
  {:tag :div
   :attrs {:class "back-link-container"}
   :content
   [{:tag :a :attrs {:href url}
     :content (if
                (vector? content)
                content
                [content])}]})


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
  ([field-or-property form entity application]
   (prompt field-or-property))
  ([field-or-property]
   (or
     (first
       (children
         field-or-property
         #(and
            (= (:tag %) :prompt)
            (= (:locale :attrs %) *locale*))))

     (:name (:attrs field-or-property))
     (:property (:attrs field-or-property)))))


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


(defn select-widget
  [property form entity application]
  (let [farname (:entity (:attrs property))
        farside (first (children application #(= (:name (:attrs %)) farname)))
        magnitude (try (read-string (:magnitude (:attrs farside))) (catch Exception _ 7))
        async? (and (number? magnitude) (> magnitude 1))
        widget-name (:name (:attrs property))]
    {:tag :div
     :attrs {:class "select-box" :farside farname :found (if farside "true" "false")}
     :content
     (apply
       vector
       (remove
         nil?
         (list
           (if
             async?
             {:tag :input
              :attrs
              {:name (str widget-name "-search-box")
               :onchange "/* javascript to repopulate the select widget */"}})
           {:tag :select
            :attrs (merge
                     {:id widget-name
                      :name widget-name}
                     (if
                       (= (:type (:attrs property)) "link")
                       {:multiple "multiple"})
                     (if
                       async?
                       {:comment "JavaScript stuff to fix up aynchronous loading"}))
            :content (apply vector (get-options property form entity application))})))}))


(defn widget
  "Generate a widget for this `field-or-property` of this `form` for this `entity`
  taken from within this `application`."
  [field-or-property form entity application]
  (let
    [widget-name (if (= (:tag field-or-property) :property)
                   (:name (:attrs field-or-property))
                   (:property (:attrs field-or-property)))
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
                 (str "{% ifwritable " (:name (:attrs entity)) " " (:name (:attrs property)) " %}")
                 (cond
                   select?
                   (select-widget property form entity application)
                   true
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
                 (str "{% ifreadable " (:name (:attrs entity)) " " (:name (:attrs property)) "%}")
                 {:tag :span
                  :attrs {:id widget-name
                          :name widget-name
                          :class "pseudo-widget disabled"}
                  :content [(str "{{record." widget-name "}}")]}
                 "{% endifreadable %}"
                 "{% endifwritable %}"]})))


(defn fields
  [form]
  (descendants-with-tag form :field))



(defn form-to-template
  "Generate a template as specified by this `form` element for this `entity`,
  taken from this `application`. If `form` is nill, generate a default form
  template for the entity."
  [form entity application]
  (let
    [keyfields (children
                 ;; there should only be one key; its keys are properties
                 (first (children entity #(= (:tag %) :key))))]
    {:tag :div
     :attrs {:id "content" :class "edit"}
     :content
     [{:tag :form
       :attrs {:action (str "{{servlet-context}}/" (editor-name entity application))
               :method "POST"}
       :content (flatten
                  (list
                    (csrf-widget)
                    (map
                      #(widget % form entity application)
                      keyfields)
                    (map
                      #(widget % form entity application)
                      (fields entity))
                    (save-widget form entity application)
                    (delete-widget form entity application)))}]}))



(defn page-to-template
  "Generate a template as specified by this `page` element for this `entity`,
  taken from this `application`. If `page` is nil, generate a default page
  template for the entity."
  [page entity application]
  )


(defn- list-thead
  "Return a table head element for the list view for this `list-spec` of this `entity` within
  this `application`.

  TODO: where entity fields are being shown/searched on, we should be using the user-distinct
  fields of the far side, rather than key values"
  [list-spec entity application]
  {:tag :thead
   :content
   [{:tag :tr
     :content
     (apply
       vector
       (map
         #(hash-map
            :content [(prompt %)]
            :tag :th)
         (fields list-spec)))}
    {:tag :tr
     :content
     (apply
       vector

       (map
         (fn [f]
           (let [property (first
                            (children
                              entity
                              (fn [p] (and (= (:tag p) :property)
                                           (= (:name (:attrs p)) (:property (:attrs f)))))))]
             (hash-map
               :tag :th
               :content
               [{:tag :input
                 :type (case (:type (:attrs property))
                         ("integer" "real" "money") "number"
                         ("date" "timestamp") "date"
                         "time" "time"
                         "text")
                 :attrs {:id (:property (:attrs f))
                         :name (:property (:attrs f))
                         :value (str "{{ params." (:property (:attrs f)) " }}")}}])))
         (fields list-spec)))}]})


(defn- list-tbody
  [list-spec entity application]
  {:tag :tbody
   :content
   ["{% for record in %records% %}"
    {:tag :tr
     :content
     (apply
       vector
       (concat
         (map
           (fn [field]
             {:tag :td :content [(str "{{ record." (:property (:attrs field)) " }}")]})
           (fields list-spec))
         [{:tag :td
          :content
          [{:tag :a
     :attrs
     {:href
      (str
        (editor-name entity application)
        "?"
        (s/join
          "&amp;"
          (map
            #(let [n (:name (:attrs %))]
               (str n "={{ record." n "}}"))
            (children (first (filter #(= (:tag %) :key) (children entity)))))))}
     :content ["View"]}]}]))}
    "{% endfor %}"]})


(defn- list-to-template
  "Generate a template as specified by this `list` element for this `entity`,
  taken from this `application`. If `list` is nill, generate a default list
  template for the entity."
  [list-spec entity application]
  {:tag :form
   :attrs {:id "content" :class "list"}
   :content
   [(big-link (str "Add a new " (pretty-name entity)) (editor-name entity application))
    {:tag :table
     :attrs {:caption (:name (:attrs entity))}
     :content
     [(list-thead list-spec entity application)
      (list-tbody list-spec entity application)
      {:tag :tfoot}]}
    "{% if offset > 0 %}"
    (back-link "Previous" "FIXME")
    "{% endif %}"
    (big-link "Next" "FIXME")
    (big-link (str "Add a new " (pretty-name entity)) (editor-name entity application))]})


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
          (apply merge (map #(assoc {} (keyword (path-part % entity application))
                               (form-to-template % entity application))
                            forms))
          {(keyword (str "form-" (:name (:attrs entity))))
           (form-to-template nil entity application)})
        (if
          pages
          (apply merge (map #(assoc {} (keyword (path-part % entity application))
                               (page-to-template % entity application))
                            pages))
          {(keyword (str "page-" (:name (:attrs entity))))
           (page-to-template nil entity application)})
        (if
          lists
          (apply merge (map #(assoc {} (keyword (path-part % entity application))
                               (list-to-template % entity application))
                            lists))
          {(keyword (str "list-" (:name (:attrs entity))))
           (form-to-template nil entity application)})))))



(defn application-to-template
  [application]
  (let
    [first-class-entities (filter
                            #(children-with-tag % :list)
                            (children-with-tag application :entity))]
    {:application-index
     {:tag :dl
      :attrs {:class "index"}
      :content
      (apply
        vector
        (interleave
          (map
            #(hash-map
               :tag :dt
               :content
               [{:tag :a
                 :attrs {:href (path-part :list % application)}
                 :content [(pretty-name %)]}])
            first-class-entities)
          (map
            #(hash-map
               :tag :dd
               :content (apply
                          vector
                          (map
                            (fn [d]
                              (hash-map
                                :tag :p
                                :content (:content d)))
                            (children-with-tag % :documentation))))
            first-class-entities)))}}))



(defn write-template-file
  [filename template]
  (if
    template
    (try
      (spit
        (str *output-path* filename)
        (s/join
          "\n"
          (list
            (file-header filename)
            (with-out-str
              (x/emit-element template))
            (file-footer filename))))
      (catch Exception any
        (spit
          (str *output-path* filename)
          (with-out-str
            (println
              (str
                "<!-- Exception "
                (.getName (.getClass any))
                (.getMessage any)
                " while printing "
                filename "-->"))
            (p/pprint template))))))
  filename)


(defn to-selmer-templates
  "Generate all [Selmer](https://github.com/yogthos/Selmer) templates implied by this ADL `application` spec."
  [application]
  (let
    [templates-map (reduce
                     merge
                     (application-to-template application)
                     (map
                       #(entity-to-templates % application)
                       (children application #(= (:tag %) :entity))))]
    (doall
      (map
        #(if
           (templates-map %)
           (let [filename (str (name %) ".html")]
             (try
               (write-template-file filename (templates-map %))
               (catch Exception any
                 (str
                   "Exception "
                   (.getName (.getClass any))
                   (.getMessage any)
                   " while writing "
                   filename)))))
        (keys templates-map)))))


