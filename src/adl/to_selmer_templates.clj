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
   [{:tag :a :attrs {:href url :class "big-link"}
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
   (let [content
         (:content
          (first
           (or (children-with-tag spec k)
               (children-with-tag entity k)
               (children-with-tag
                (child-with-tag application :content)
                k))))]
     (if
       content
       (flatten
        (list
         (str "{% block " (name k) " %}")
         (doall
          (map
           #(with-out-str (x/emit-element %))
           content))
         "{% endblock %}"))))))


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
         (emit-content filename spec entity application :top))))))


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
         (emit-content filename spec entity application :foot))))))


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
     fs-distinct (user-distinct-properties farside)
     farkey (or
              (:farkey (:attrs property))
              (first (key-names farside))
              "id")]
    [(str "{% for r in " farname " %}<option value='{{r."
          farkey
          "}}' {% ifequal record."
          (-> property :attrs :name)
          " r." farkey "%}selected{% endifequal %}>"
          (s/join " " (map #(str "{{r." (:name (:attrs %)) "}}") fs-distinct))
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
     (if
       (= (-> property :attrs :distinct) "system")
       "hidden" ;; <- this is slightly wrong. There are some circumstances in which
                ;; system-distinct properties might be user-editable
       (case t
         ("integer" "real" "money") "number"
         ("uploadable" "image") "file"
         ("entity" "link") "select"
         "boolean" "checkbox"
         "date" "date"
         "time" "time"
         "text" ;; default
         )))))


(defn select-widget
  ;; TODO: rewrite for selectize https://github.com/selectize/selectize.js/blob/master/docs/usage.md
  ;; https://gist.github.com/zabolotnov87/11142887
  [property form entity application]
  (let [farname (:entity (:attrs property))
        farside (first (children application #(= (:name (:attrs %)) farname)))
        magnitude (try (read-string (:magnitude (:attrs farside))) (catch Exception _ 7))
        async? (and (number? magnitude) (> magnitude 1))
        widget-name (safe-name (:name (:attrs property)) :sql)]
    {:tag :span
     :attrs {:class "select-box" :farside farname :found (if farside "true" "false")}
     :content
     (apply
       vector
       (remove
         nil?
         (flatten
           (list
             (if
               async?
               (list
                 {:tag :input
                  :attrs
                  {:name (str widget-name "_search_box")
                   :onchange (str "$.getJSON(\"/auto/json/seach-strings-"
                                  (-> farside :attrs :name)
                                  "?"
                                  (s/join (str "=\" + " widget-name "_search_box.text + \"&amp;")
                                          (user-distinct-property-names farside))
                                  (str "=\" + " widget-name "_search_box.text")
                                  ", null, function (data) {updateMenuOptions(\""
                                  widget-name "\", \""
                                  (first (key-names farside))
                                  "\", [\""
                                  (s/join "\", \"" (user-distinct-property-names farside))
                                  "\"], data);})")}}
                 {:tag :br}))
             {:tag :select
              :attrs (merge
                       {:id widget-name
                        :name widget-name}
                       (if
                         (= (:type (:attrs property)) "link")
                         {:multiple "multiple"}))
              :content (apply vector (get-options property form entity application))}))))}))


(defn compose-if-member-of-tag
  [property entity application writable?]
  (let
    [all-permissions (find-permissions property entity application)
     permissions (map
                   s/lower-case
                   (if
                     writable?
                     (writable-by all-permissions)
                     (visible-to all-permissions)))]
    (s/join
     " "
     (flatten
      (list
       "{% ifmemberof"
       permissions
       "%}")))))


(defn compose-widget-para
  [p f e a w content]
  {:tag :p
   :attrs {:class "widget"}
   :content [{:tag :label
              :attrs {:for w}
              :content [(prompt p f e a)]}
             (compose-if-member-of-tag p e a true)
             content
             "{% else %}"
             (compose-if-member-of-tag p e a false)
             {:tag :span
              :attrs {:id w
                      :name w
                      :class "pseudo-widget disabled"}
              :content [(str "{{record." w "}}")]}
             "{% else %}"
             {:tag :span
              :attrs {:id w
                      :name w
                      :class "pseudo-widget not-authorised"}
              :content [(str "You are not permitted to view " w " of " (:name (:attrs e)))]}
             "{% endifmemberof %}"
             "{% endifmemberof %}"]})


(defn widget
  "Generate a widget for this `field-or-property` of this `form` for this `entity`
  taken from within this `application`."
  [field-or-property form entity application]
  (let
    [widget-name (safe-name
                   (if (= (:tag field-or-property) :property)
                     (:name (:attrs field-or-property))
                     (:property (:attrs field-or-property))) :sql)
     property (if
                (= (:tag field-or-property) :property)
                field-or-property
                (child-with-tag entity
                                :property
                                #(= (:name (:attrs %))
                                    (:property (:attrs field-or-property)))))
     permissions (find-permissions field-or-property property form entity application)
     typedef (typedef property application)
     w-type (widget-type property application typedef)
     visible-to (visible-to permissions)
     ;; if the form isn't actually a form, no widget is writable.
     writable-by (if (= (:tag form) :form) (writable-by permissions))]
    (case w-type
      "hidden"
      {:tag :input
       :attrs {:id widget-name
               :name widget-name
               :type "hidden"
               :value (str "{{record." widget-name "}}")}}
      "select"
      (compose-widget-para field-or-property form entity application widget-name
                           (select-widget property form entity application))
      ;; all others
      (compose-widget-para
        field-or-property form entity application widget-name
        {:tag :input
         :attrs (merge
                  {:id widget-name
                   :name widget-name
                   :type w-type
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
                    {:max (:maximum (:attrs typedef))}))}))))


(defn compose-select-script-header [entity application]
  {:tag :script :attrs {:type "text/javascript"}
    :content
    [(slurp "resources/js/select-widget-support.js")]})


(defn form-to-template
  "Generate a template as specified by this `form` element for this `entity`,
  taken from this `application`. If `form` is nill, generate a default form
  template for the entity."
  [form entity application]
  (merge
    {:content
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
                     (delete-widget form entity application)))}]}}
     (if
       (some #(= "select" (widget-type % application)) (properties entity))
       {:extra-head (compose-select-script-header entity application)}
       {})))


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
        search-name (safe-name
                      (if
                        (= (:type (:attrs property)) "entity")
                        (str base-name "_expanded") base-name)
                      :sql)]
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
     (conj
       (apply
         vector
         (map
           #(hash-map
              :content [(prompt %)]
              :tag :th)
           (children-with-tag list-spec :field)))
       {:tag :th :content ["&nbsp;"]})}
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
                      :id "search-widget"
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
                s (safe-name (:name (:attrs p)) :sql)
                e (first
                    (filter
                      #(= (:name (:attrs %)) (:entity (:attrs p)))
                      (children-with-tag application :entity)))
                c (str "{{ record." s " }}")]
               (if
                 (= (:type (:attrs p)) "entity")
                 [{:tag :a
                   :attrs {:href (edit-link e application (list (:name (:attrs p))))}
                   :content [(str "{{ record." s "_expanded }}")]}]
                 [c]))})
           (children-with-tag list-spec :field))
         [{:tag :td
          :content
          [{:tag :a
     :attrs
     {:href (edit-link entity application (key-names entity))}
     :content ["View"]}]}]))}
    "{% endfor %}"]})


(defn list-to-template
  "Generate a template as specified by this `list` element for this `entity`,
  taken from this `application`. If `list` is nill, generate a default list
  template for the entity."
  [list-spec entity application]
  (let [form-name
        (str
         "list-"
         (:name (:attrs entity))
         "-"
         (:name (:attrs list-spec)))]
    {:back-links
     {:tag :div
      :content
      [
       {:tag :div :attrs {:class "back-link-container"}
        :content
        ["{% ifequal params.offset \"0\" %}"
          {:tag :a
          :attrs {:id "back-link" :class "back-link" :href "{{servlet-context}}/admin"}
          :content ["Back"]}
         "{% else %}"
          {:tag :a :attrs {:id "prev-selector" :class "back-link"}
          :content ["Previous"]}
         "{% endifunequal %}"]}
       ]}
     :big-links
     {:tag :div
      :content
      [{:tag :div :attrs {:class "big-link-container"}
        :content
        [{:tag :a :attrs {:id "next-selector" :role "button" :class "big-link"}
          :content ["Next"]}]}
       (big-link (str "Add a new " (pretty-name entity)) (editor-name entity application))]}
     :content
     {:tag :form
      :attrs {:id form-name :class "list"
              :action (str "{{servlet-context}}/" form-name)
              :method "POST"}
      :content
      [(csrf-widget)
       {:tag :input :attrs {:id "offset" :type "hidden" :value "{{params.offset|default:0}}"}}
       {:tag :input :attrs {:id "limit" :type "hidden" :value "{{params.limit|default:50}}"}}
       {:tag :table
        :attrs {:caption (:name (:attrs entity))}
        :content
          [(list-thead list-spec entity application)
           (list-tbody list-spec entity application)
           ]}]}
     :extra-script
     (str "
          var form = document.getElementById('" form-name "');
          var ow = document.getElementById('offset');
          var lw = document.getElementById('limit');
          form.addEventListener('submit', function() {
            ow.value='0';
          });

          {% ifunequal params.offset \"0\" %}
          document.getElementById('prev-selector').addEventListener('click', function () {
            ow.value=(parseInt(ow.value)-parseInt(lw.value));
            console.log('Updated offset to ' + ow.value);
            form.submit();
          });
          {% endifunequal %}

          document.getElementById('next-selector').addEventListener('click', function () {
            ow.value=(parseInt(ow.value)+parseInt(lw.value));
            console.log('Updated offset to ' + ow.value);
            form.submit();
          });")}))


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
    [first-class-entities
     (sort-by
      #(:name (:attrs %))
      (filter
       #(children-with-tag % :list)
       (children-with-tag application :entity)))]
    {:application-index
     {:content
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
          first-class-entities)))}}}))


(defn write-template-file
  [filename template application]
  (let [filepath (str *output-path* "resources/templates/auto/" filename)]
    (if
      template
      (try
        (do
          (spit
           filepath
           (s/join
            "\n"
            (flatten
             (list
              (file-header filename application)
              (doall
               (map
                #(let [content (template %)]
                   (list
                    (str "{% block " (name %) " %}")
                    (cond (string? content)
                          content
                          (map? content)
                          (with-out-str
                            (x/emit-element content))
                          true
                          (str "<!-- don't know what to do with '" content "' -->"))
                    "{% endblock %}"))
                   (keys template)))
              (file-footer filename application)))))
          (if (> *verbosity* 0) (println "\tGenerated " filepath)))
        (catch Exception any
          (let [report (str
                        "ERROR: Exception "
                        (.getName (.getClass any))
                        (.getMessage any)
                        " while printing "
                        filepath)]
            (try
              (spit
               filepath
               (with-out-str
                 (println (str "<!-- " report "-->"))
                 (p/pprint template)))
              (catch Exception _ nil))
            (println report)
            (throw any)))))
    (str filepath)))


;; (def a (x/parse "../youyesyet/youyesyet.canonical.adl.xml"))
;; (def e (child-with-tag a :entity))
;; (def f (child-with-tag e :form))
;; (write-template-file "froboz" (form-to-template f e a) a)
;; (def t (form-to-template f e a))
;; (map type t)
;; t



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


