(ns ^{:doc "Application Description Language - generate Selmer templates for the HTML pages implied by an ADL file."
      :author "Simon Brooke"}
  adl.to-selmer-templates
  (:require [adl-support.utils :refer :all]
            [clojure.java.io :refer [file make-parents]]
            [clojure.pprint :as p]
            [clojure.string :as s]
            [clojure.xml :as x]
            [clj-time.core :as t]
            [clj-time.format :as f]
            [hiccup.core :as h]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; adl.to-selmer-templates. Generate Web 1.0 style user interface.
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


(defn emit-content
  ([filename application k]
   (emit-content filename nil nil application k))
  ([filename spec entity application k]
   (let [content (:content
                   (first
                     (or (children-with-tag spec k)
                         (children-with-tag entity k)
                         (children-with-tag
                           (first
                             (children-with-tag application :content))
                           k))))]
     (if
       content
       (list
         (str "{% block " (name k) " %}")
         (map
           #(with-out-str (x/emit-element %))
           content)
         "{% endblock %}")))))


(defn file-header
  "Generate a header for a template file with this `filename` for this `spec`
  of this `entity` within this `application`."
  ([filename application]
   (file-header filename nil nil application))
  ([filename spec entity application]
   (s/join
     "\n"
     (flatten
       (list
         "{% extends \"base.html\" %}"
         (str "<!-- File "
              filename
              " generated "
              (t/now)
              " by adl.to-selmer-templates.\n"
              "See [Application Description Language](https://github.com/simon-brooke/adl)."
              "-->")
         (emit-content filename spec entity application :head)
         (emit-content filename spec entity application :top)
         "{% block content %}")))))


(defn file-footer
  "Generate a footer for a template file with this `filename` for this `spec`
  of this `entity` within this `application`."
  ([filename application]
   (file-footer filename nil nil application))
  ([filename spec entity application]
   (s/join
     "\n"
     (flatten
       (list
         "{% endblock %}"
         (emit-content filename spec entity application :foot)
         )))))


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
  from this `application`.
  TODO: should be suppressed unless a member of a group which can insert or edit."
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
                      :type "submit"
                      :value (str "Save!")}}]})


(defn delete-widget
  "Return an appropriate 'save' widget for this `form` operating on this `entity` taken
  from this `application`.
  TODO: should be suppressed unless member of a group which can delete."
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
                      :type "submit"
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


(defn compose-if-member-of-tag
  [property entity application writable?]
  (let
    [all-permissions (find-permissions property entity application)
     permissions (if writable? (writable-by all-permissions) (visible-to all-permissions))]
    (s/join
     " "
     (flatten
      (list
       "{% ifmemberof"
       permissions
       "%}")))))


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
                (child-with-tag entity
                                :property
                                #(= (:name (:attrs %))
                                    (:property (:attrs field-or-property)))))
     permissions (find-permissions field-or-property property form entity application)
     typedef (typedef property application)
     visible-to (visible-to permissions)
     ;; if the form isn't actually a form, no widget is writable.
     writable-by (if (= (:tag form) :form) (writable-by permissions))
     select? (#{"entity" "list" "link"} (:type (:attrs property)))]
    (if
      (= (:distinct (:attrs property)) "system")
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
                 (compose-if-member-of-tag property entity application true)
                 (cond
                   select?
                   (select-widget property form entity application)
                   true
                   {:tag :input
                    :attrs (merge
                             {:id widget-name
                              :name widget-name
                              :type (widget-type property application typedef)
                              :value (str "{{record." widget-name "}}")
                              :maxlength (:size (:attrs property))
                              :size (cond
                                      (nil? (:size (:attrs property)))
                                      "16"
                                      (try
                                        (> (read-string
                                             (:size (:attrs property))) 60)
                                        (catch Exception _ false))
                                      "60"
                                      true
                                      (:size (:attrs property)))}
                             (if
                               (:minimum (:attrs typedef))
                               {:min (:minimum (:attrs typedef))})
                             (if
                               (:maximum (:attrs typedef))
                               {:max (:maximum (:attrs typedef))}))})
                 "{% else %}"
                 (compose-if-member-of-tag property entity application false)
                 {:tag :span
                  :attrs {:id widget-name
                          :name widget-name
                          :class "pseudo-widget disabled"}
                  :content [(str "{{record." widget-name "}}")]}
                 "{% else %}"
                 {:tag :span
                  :attrs {:id widget-name
                          :name widget-name
                          :class "pseudo-widget not-authorised"}
                  :content [(str "You are not permitted to view " widget-name " of " (:name (:attrs entity)))]}
                 "{% endifmemberof %}"
                 "{% endifmemberof %}"]})))


(defn form-to-template
  "Generate a template as specified by this `form` element for this `entity`,
  taken from this `application`. If `form` is nill, generate a default form
  template for the entity."
  [form entity application]
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
                    (children-with-tag (child-with-tag entity :key) :properties))
                  (map
                    #(widget % form entity application)
                    (remove
                      #(let
                         [property (filter
                                     (fn [p] (= (:name (:attrs p)) (:property (:attrs %))))
                                     (descendants-with-tag entity :property))]
                         (= (:distict (:attrs property)) :system))
                      (children-with-tag form :field)))
                  (save-widget form entity application)
                  (delete-widget form entity application)))}]})


(defn page-to-template
  "Generate a template as specified by this `page` element for this `entity`,
  taken from this `application`. If `page` is nil, generate a default page
  template for the entity."
  [page entity application]
  ;; TODO
  )


(defn compose-list-search-widget
  [field entity]
  (let [property (first
                   (children
                     entity
                     (fn [p] (and (= (:tag p) :property)
                                  (= (:name (:attrs p)) (:property (:attrs field)))))))
        input-type (case (:type (:attrs property))
                     ("integer" "real" "money") "number"
                     ("date" "timestamp") "date"
                     "time" "time"
                     "text")
        base-name (:property (:attrs field))
        search-name (if
                      (= (:type (:attrs property)) "entity")
                      (str base-name "_expanded") base-name)]
    (hash-map
      :tag :th
      :content
      [{:tag :input
        :attrs {:id search-name
                :type input-type
                :name search-name
                :value (str "{{ params." search-name " }}")}}])))



(defn- list-thead
  "Return a table head element for the list view for this `list-spec` of this `entity` within
  this `application`."
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
         (children-with-tag list-spec :field)))}
    {:tag :tr
     :content
     (apply
       vector
       (concat
         (map
           #(compose-list-search-widget % entity)
           (children-with-tag list-spec :field))
         '({:tag :th
            :content
            [{:tag :input
              :attrs {:type "submit"
                      :id "search"
                      :value "Search"}}]})))}]})


(defn edit-link
  [entity application parameters]
  (str
    (editor-name entity application)
    "?"
    (s/join
      "&amp;"
      (map
        #(str %1 "={{ record." %2 " }}")
        (key-names entity)
        parameters))))


(defn list-tbody
  "Return a table body element for the list view for this `list-spec` of this `entity` within
  this `application`."
  [list-spec entity application]
  {:tag :tbody
   :content
   ["{% for record in records %}"
    {:tag :tr
     :content
     (apply
       vector
       (concat
         (map
           (fn [field]
             {:tag :td :content
              (let
               [p (first (filter #(= (:name (:attrs %)) (:property (:attrs field))) (all-properties entity)))
                e (first
                    (filter
                      #(= (:name (:attrs %)) (:entity (:attrs p)))
                      (children-with-tag application :entity)))
                c (str "{{ record." (:property (:attrs field)) " }}")]
               (if
                 (= (:type (:attrs p)) "entity")
                 [{:tag :a
                   :attrs {:href (edit-link e application (list (:name (:attrs p))))}
                   :content [(str "{{ record." (:property (:attrs field)) "_expanded }}")]}]
                 [c]))})
           (children-with-tag list-spec :field))
         [{:tag :td
          :content
          [{:tag :a
     :attrs
     {:href (edit-link entity application (key-names entity))}
     :content ["View"]}]}]))}
    "{% endfor %}"]})


(defn- list-page-control
  "What this needs to do is emit an HTML control which, when selected, requests the
  next or previous page keeping the same search parameters; so it essentially needs
  to be a submit button, not a link."
  [forward?]
  {:tag :div
   :attrs {:class (if forward? "big-link-container" "back-link-container")}
   :content
   [{:tag :input
     :attrs {:id "page"
             :name "page"
             :disabled (if
                         forward?
                         false
                         "{% ifequal offset 0 %} false {% else %} true {% endifequal %}")
             ;; TODO: real thought needs to happen on doing i18n for this!
             :value (if forward? "Next" "Previous")}}]})


(defn- list-tfoot
  "Return a table footer element for the list view for this `list-spec` of this `entity` within
  this `application`."
  [list-spec entity application]
  {:tag :tfoot
   :content
   [(list-page-control false)
    (list-page-control true)]})


(defn list-to-template
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
      (list-tfoot list-spec entity application)]}]})


(defn entity-to-templates
  "Generate one or more templates for editing instances of this
  `entity` in this `application`"
  [entity application]
  (let
    [forms (children-with-tag entity :form)
     pages (children-with-tag entity :page)
     lists (children-with-tag entity :list)]
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
  [filename template application]
  (let [filepath (str *output-path* "resources/templates/auto/" filename)]
    (make-parents filepath)
    (if
      template
      (try
        (spit
          filepath
          (s/join
            "\n"
            (list
              (file-header filename application)
              (with-out-str
                (x/emit-element template))
              (file-footer filename application))))
        (if (> *verbosity* 0) (println "\tGenerated " filepath))
        (catch Exception any
          (let [report (str
                         "ERROR: Exception "
                         (.getName (.getClass any))
                         (.getMessage any)
                         " while printing "
                         filename)]
            (spit
              filepath
              (with-out-str
                (println (str "<!-- " report "-->"))
                (p/pprint template)))
            (println report)))))
    (str filepath)))


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
               (write-template-file filename (templates-map %) application)
               (catch Exception any
                 (println
                   (str
                     "ERROR: Exception "
                     (.getName (.getClass any))
                     (.getMessage any)
                     " while writing "
                     filename))))))
        (keys templates-map)))))


