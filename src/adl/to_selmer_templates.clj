(ns ^{:doc "Application Description Language - generate Selmer templates for
      the HTML pages implied by an ADL file."
      :author "Simon Brooke"}
  adl.to-selmer-templates
  (:require [adl-support.core :refer :all]
            [adl-support.forms-support :refer :all]
            [adl.to-hugsql-queries :refer [expanded-token]]
            [adl-support.utils :refer :all]
            [clojure.java.io :refer [file make-parents resource]]
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
   [{:tag :a
     :attrs {:href  (str "{{servlet-context}}/" url)
             :class "big-link"}
     :content (if
                (vector? content)
                content
                [content])}]})


(defn back-link
  [content url]
  {:tag :div
   :attrs {:class "back-link-container"}
   :content
   [{:tag :a :attrs {:href (str "{{servlet-context}}/" url)}
     :content (if
                (vector? content)
                content
                [content])}]})


(defn emit-content
  ([content]
     (cond
       (nil? content)
       nil
       (string? content)
       content
       (and (map? content) (:tag content))
       (with-out-str
         (x/emit-element content))
       (seq? content)
       (map emit-content (remove nil? content))
       true
       (str "<!-- don't know what to do with '" content "' -->")))
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
               emit-content
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


(defn csrf-widget
  "For the present, just return the standard cross site scripting protection
  field statement"
  []
  "{% csrf-field %}")


(defn compose-if-member-of-tag
  [privilege & elts]
  (let
    [all-permissions (distinct (apply find-permissions elts))
     permissions (map
                   s/lower-case
                   (case privilege
                     :writeable (writeable-by all-permissions)
                     :editable (writeable-by all-permissions true)
                     :readable (visible-to all-permissions)))]
    (s/join
     " "
     (flatten
      (list
       "{% ifmemberof"
       permissions
       "%}")))))


(defn wrap-in-if-member-of
  "Wrap this `content` in an if-member-of tag; if `writeable?` is true,
  allow those groups by whom it is writeable, else those by whom it is
  readable. `context` should be a sequence of adl elements from which
  permissions may be obtained."
  [content privilege & context]
  [(apply compose-if-member-of-tag (cons privilege context))
   content
   "{% endifmemberof %}"])


(defn save-widget
  "Return an appropriate 'save' widget for this `form` operating on this
  `entity` taken from this `application`.
  TODO: should be suppressed unless a member of a group which can insert
  or edit."
  [form entity application]
  (wrap-in-if-member-of
    {:tag :p
     :attrs {:class "widget action-safe"}
     :content [{:tag :label
                :attrs {:for "save-button" :class "action-safe"}
                :content [(str
                           "To save this "
                           (:name (:attrs entity))
                           " record")]}
               {:tag :input
                :attrs {:id "save-button"
                        :name "save-button"
                        :class "action-safe"
                        :type "submit"
                        :value (str "Save!")}}]}
    :editable
    entity
    application))


(defn delete-widget
  "Return an appropriate 'save' widget for this `form` operating on this
  `entity` taken from this `application`."
  [form entity application]
  (flatten
   (list
    (str "{% if all "
         (s/join " " (map #(str "params." %) (key-names entity)))
         " %}")

    (wrap-in-if-member-of
     {:tag :p
      :attrs {:class "widget action-dangerous"}
      :content [{:tag :label
                 :attrs {:for "delete-button"
                         :class "action-dangerous"}
                 :content [(str
                            "To delete this "
                            (:name (:attrs entity))
                            " record")]}
                {:tag :input
                 :attrs {:id "delete-button"
                         :name "delete-button"
                         :class "action-dangerous"
                         :type "submit"
                         :value (str "Delete!")}}]}
     :editable
     entity
     application)
    "{% endif %}")))


(defn select-property
  "Return the property on which we will by default do a user search on this
  `entity`."
  [entity]
  (descendant-with-tag
      entity
      :property
      #(#{"user" "all"} (-> % :attrs :distinct))))


(defn select-field-name
  [entity]
  (let [p (select-property entity)]
    (if
      (-> p :attrs :entity)
      (str (safe-name p :sql) expanded-token)
      (-> p :attrs :name))))


(defn get-options
  "Produce template code to get options for this `property` of this `entity`
  taken from this `application`."
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
    ;; Yes, I know it looks BONKERS generating this as an HTML string. But
    ;; there is a reason. We don't know whether the `selected` attribute
    ;; should be present or absent until rendering.
    [(str "{% for option in " (-> property :attrs :name)
          " %}<option value='{{option."
          farkey
          "}}' {% ifequal record."
          (-> property :attrs :name)
          " option." farkey "%}selected='selected'{% endifequal %}>"
          "{{option." (select-field-name farside)
          "}}</option>{% endfor %}")]))


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
       (and
        (= (-> property :attrs :distinct) "system")
        (= (-> property :attrs :immutable) "true"))
       "hidden"
       (case t
         ("integer" "real" "money") "number"
         ("uploadable" "image") "file"
         ("entity" "link") "select"
         "boolean" "checkbox"
         "date" "date"
         "time" "time"
         "text" "text-area"
         ;; default
         "string")))))


(defn select-widget
  [property form entity application]
  (let [farname (:entity (:attrs property))
        farside (first
                 (children
                  application
                  #(= (:name (:attrs %)) farname)))
        magnitude (try
                    (read-string (:magnitude (:attrs farside)))
                    (catch Exception _ 7))
        async? (and (number? magnitude) (> magnitude 1))
        widget-name (safe-name (:name (:attrs property)) :sql)]
    {:tag :select
     :attrs (merge
              {:id widget-name
               :name widget-name}
              (if
                (= (:type (:attrs property)) "link")
                {:multiple "multiple"}))
     :content (apply
               vector
               (get-options property form entity application))}))


(defn compose-readable-or-not-authorised
  [p f e a w]
  (list
    (compose-if-member-of-tag :readable p e a)
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
     :content [(str
                "You are not permitted to view "
                w
                " of "
                (:name (:attrs e)))]}
    "{% endifmemberof %}"))


(defn compose-widget-para
  [p f e a w content]
  {:tag :p
   :attrs {:class "widget"}
   :content (apply
              vector
              (flatten
                (list
                  {:tag :label
                   :attrs {:for w}
                   :content [(prompt p f e a)]}
                  (str "{% if {{record." (-> p :attrs :name) "}} %}")
                  (compose-if-member-of-tag :editable p e a)
                  content
                  "{% else %}"
                  (compose-readable-or-not-authorised p f e a w)
                  "{% endifmemberof %}"
                  "{% else %}"
                  (compose-if-member-of-tag :writeable p e a)
                  content
                  "{% else %}"
                   (compose-readable-or-not-authorised p f e a w)
                  "{% endifmemberof %}"
                  "{% endif %}")))})


(defn get-size-for-widget
  "Return, as an integer, the fieldwidth for the input widget for this
  `property`."
  [property]
  (let [s (try
            (read-string
             (:size (:attrs property)))
            (catch Exception _ 16))]
  (if
   (not (integer? s))
   16
   s)))


(defn compose-input-widget-para
  "Generate an input widget for this `field-or-property` of this `form` for
  this `entity` taken from within this `application`, in context of a para
  also containing its label."
  [property form entity application widget-name]
  (let
    [typedef (typedef property application)
     w-type (widget-type property application typedef)]
    (compose-widget-para
     property form entity application widget-name
     {:tag :input
      :attrs (merge
              {:id widget-name
               :name widget-name
               :type w-type
               :value (str "{{record." widget-name "}}")
               :maxlength (str (max (get-size-for-widget property) 16))
               :size (str (min (get-size-for-widget property) 60))}
              (case (-> property :attrs :type)
                "real"
                {:step 0.000001} ;; this is a bit arbitrary!
                "integer"
                {:step 1}
                nil)
              ;; TODO: should match pattern from typedef
              (if
                (:minimum (:attrs typedef))
                {:min (:minimum (:attrs typedef))})
              (if
                (:maximum (:attrs typedef))
                {:max (:maximum (:attrs typedef))}))})))


(defn widget
  "Generate a widget for this `field-or-property` of this `form` for this
  `entity` taken from within this `application`, in context of a para also
  containing its label."
  [field-or-property form entity application]
  (let
    [widget-name (safe-name
                   (if (= (:tag field-or-property) :property)
                     (:name (:attrs field-or-property))
                     (:property (:attrs field-or-property))) :sql)
     property (case
                (:tag field-or-property)
                :property field-or-property
                :field (property-for-field field-or-property entity)
                ;; default
                nil)
     typedef (typedef property application)
     w-type (widget-type property application typedef)]
    (if
      property
      (case w-type
        "hidden"
        {:tag :input
         :attrs {:id widget-name
                 :name widget-name
                 :type "hidden"
                 :value (str "{{record." widget-name "}}")}}
        "select"
        (compose-widget-para
         property
         form
         entity
         application
         widget-name
         (select-widget property form entity application))
        "text-area"
        (compose-widget-para
         property form entity application widget-name
         {:tag :textarea
          :attrs {:rows "8" :cols "60" :id widget-name :name widget-name}
          :content [(str "{{record." widget-name "}}")]})
        ;; all others
        (compose-input-widget-para
         property
         form
         entity
         application
         widget-name)))))


(defn embed-script-fragment
  "Return the content of the file at `resource-path`, with these
  `substitutions` made into it in order. Substitutions should be pairs
  [`pattern` `value`], where `pattern` is a string, a char, or a regular
  expression."
  ([resource-path substitutions]
   (let [v (slurp (resource resource-path))]
     (reduce
       (fn [s [pattern value]]
         (if (and pattern value)
           (s/replace s pattern value)
           s))
       v
       substitutions)))
  ([resource-path]
   (embed-script-fragment resource-path [])))


(defn edit-link
  [source entity application parameters]
  (str
    "{{servlet-context}}/"
    (or
     (-> source :attrs :onselect)
     (editor-name entity application))
    "?"
    (s/join
      "&amp;"
      (map
        #(str %1 "={{ record." %2 " }}")
        (key-names entity)
        parameters))))


(defn list-tbody
  "Return a table body element for the list view for this `list-spec` of
  this `entity` within this `application`, using data from this `source`."
  [source list-spec entity application]
  {:tag :tbody
   :content
   [(str "{% for record in " source " %}")
    {:tag :tr
     :content
     (apply
      vector
      (remove
       nil?
       (concat
        (map
         (fn [field]
           {:tag :td :content
            (let
              [p (first
                  (filter
                   #(=
                     (:name (:attrs %))
                     (:property (:attrs field)))
                   (all-properties entity)))
               s (safe-name (:name (:attrs p)) :sql)
               e (first
                  (filter
                   #(= (:name (:attrs %)) (:entity (:attrs p)))
                   (children-with-tag application :entity)))
               c (str "{{ record." s " }}")]
              (if
                (= (:type (:attrs p)) "entity")
                [{:tag :a
                  :attrs {:href (edit-link
                                 source
                                 (child-with-tag
                                  application
                                  :entity
                                  #(= (-> % :attrs :name)(-> p :attrs :entity)))
                                 application
                                 (list (:name (:attrs p))))}
                  :content [(str "{{ record." s "_expanded }}")]}]
                [c]))})
         (children-with-tag list-spec :field))
        [{:tag :td
          :content
          [(if
             (or (= (:tag list-spec) :list)
                 (-> list-spec :attrs :onselect))
             {:tag :a
              :attrs
              {:href (edit-link source entity application (key-names entity))}
              :content ["View"]}
             "&nbsp;")]}])))}
    "{% endfor %}"]})


(defn compose-form-auxlist
  [auxlist form entity application]
  (let [property (child-with-tag
                   entity
                   :property
                   #(=
                      (-> % :attrs :name)
                      (-> auxlist :attrs :property)))
        farside (child-with-tag
                  application
                  :entity
                  #(=
                     (-> % :attrs :name)
                     (-> property :attrs :entity)))]
    (if
      (and property farside)
      {:tag :div
       :attrs {:class "auxlist"}
       :content
       (apply
         vector
         (remove
           nil?
           (flatten
             (list
               ;; only show auxlists if we've got keys
               (str "{% if all "
                    (s/join " " (map #(str "params." %) (key-names entity)))
                    " %}")
               ;; only show the body of auxlists if the list is non-empty
               (str "{% if " (auxlist-data-name auxlist) "|not-empty %}")

               {:tag :h2
                :content [(prompt auxlist form entity application)]}
               {:tag :table
                :content
                [{:tag :thead
                  :content
                  [{:tag :tr
                    :content
                    (apply
                      vector
                      (remove
                        nil?
                        (flatten
                          (list
                            (map
                              #(hash-map
                                 :tag :th
                                 :content [(prompt % form entity application)])
                              (children-with-tag auxlist :field))
                            {:tag :th :content ["&nbsp;"]}))))}]}
                 (list-tbody
                   (auxlist-data-name auxlist)
                   auxlist
                   farside
                   application)]}
               "{% endif %}"
               (if
                 (= (-> auxlist :attrs :canadd) "true")
                 (wrap-in-if-member-of
                   (big-link (str
                               "Add a new "
                               (pretty-name property))
                             (editor-name farside application))
                   :writeable
                   farside
                   application)
                 )
               "{% endif %}"))))})))


(defn compose-form-auxlists
  [form entity application]
  (remove
    nil?
    (map
      #(compose-form-auxlist % form entity application)
      (children-with-tag form :auxlist))))


(defn compose-form-content
  [form entity application]
  {:content
   {:tag :div
    :attrs {:id "content" :class "edit"}
    :content
    (apply
     vector
     (cons
      {:tag :form
       :attrs {:action (str
                        "{{servlet-context}}/"
                        (editor-name entity application))
               :method "POST"}
       :content (apply
                 vector
                 (remove
                  nil?
                  (flatten
                   (list
                    (csrf-widget)
                    (map
                     #(widget % form entity application)
                     (children-with-tag
                      (child-with-tag entity :key)
                      :property))
                    (map
                     #(widget % form entity application)
                     (remove
                      #(let
                         [property
                          (filter
                           (fn
                             [p]
                             (= (:name (:attrs p)) (:property (:attrs %))))
                           (descendants-with-tag entity :property))]
                         (= (:distict (:attrs property)) :system))
                      (children-with-tag form :field)))
                    (save-widget form entity application)
                    (delete-widget form entity application)))))}
      (compose-form-auxlists form entity application)))}})


(defn compose-form-extra-head
  [form entity application]
  {:extra-head
   (apply
     str
     (remove
       nil?
       (list
         (if
           (child-with-tag
             form
             :field
             #(=
               "text-area"
               (widget-type (property-for-field % entity) application)))
           "
           {% script \"/js/lib/node_modules/simplemde/dist/simplemde.min.js\" %}
           {% style \"/js/lib/node_modules/simplemde/dist/simplemde.min.css\" %}")
         (if
           (child-with-tag
             form
             :field
             #(=
               "select"
               (widget-type (property-for-field % entity) application)))
           "
           {% script \"/js/lib/node_modules/selectize/dist/js/standalone/selectize.min.js\" %}
           {% style \"/js/lib/node_modules/selectize/dist/css/selectize.css\" %}"))))})


(defn compose-form-extra-tail
  [form entity application]
  {:extra-tail
   {:tag :script :attrs {:type "text/javascript"}
    :content
    (apply
     vector
     (remove
      nil?
      (flatten
       (list
        (map
         (fn [field]
           (let
             [property (child-with-tag
                        entity
                        :property
                        #(=
                          (-> field :attrs :property)
                          (-> % :attrs :name)))
              farname (:entity (:attrs property))
              farside (first
                       (children
                        application
                        #(= (:name (:attrs %)) farname)))
              magnitude (try
                          (read-string
                           (:magnitude
                            (:attrs farside)))
                          (catch Exception _ 7))]
             (if
               (> magnitude 2)
               (embed-script-fragment
                "js/selectize-one.js"
                [["{{widget_id}}" (-> property :attrs :name)]
                 ["{{widget_value}}"
                  (str "{{record." (-> property :attrs :name) "}}")]
                 ["{{entity}}" farname]
                 ["{{field}}" (select-field-name farside)]
                 ["{{key}}" (first (key-names farside))]]))))
         (children-with-tag
          form :field
          #(=
            "select"
            (widget-type (property-for-field % entity) application))))
        (if
          (child-with-tag
           form :field
           #(=
             "text-area"
             (widget-type (property-for-field % entity) application)))
          (embed-script-fragment
           "js/text-area-md-support.js"
           [["{{page}}" (-> form :attrs :name)]]))))))}})


(defn form-to-template
  "Generate a template as specified by this `form` element for this `entity`,
  taken from this `application`. If `form` is nill, generate a default form
  template for the entity."
  [form entity application]
  (merge
    (compose-form-extra-head form entity application)
    (compose-form-content form entity application)
    (compose-form-extra-tail form entity application)))


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
                                  (= (:name (:attrs p))
                                     (:property (:attrs field)))))))
        input-type (case (:type (:attrs property))
                     ("integer" "real" "money") "number"
                     ("date" "timestamp") "date"
                     "time" "time"
                     "text")
        base-name (:property (:attrs field))
        search-name (safe-name base-name :sql)]
    (hash-map
      :tag :th
      :content
      [{:tag :input
        :attrs {:id search-name
                :type input-type
                :name search-name
                :value (str "{{ params." search-name " }}")}}])))



(defn- list-thead
  "Return a table head element for the list view for this `list-spec` of
  this `entity` within this `application`."
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
              :content [(prompt % list-spec entity application)]
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
      [{:tag :div :attrs {:class "back-link-container"}
         :content
         [{:tag :a
           :attrs {:id "prev-selector" :class "back-link"}
           :content ["Previous"]}]}]}
     :big-links
     {:tag :div
      :content
      (apply
        vector
        (remove
          nil?
          (flatten
            (list
              {:tag :div :attrs {:class "big-link-container"}
               :content
               [{:tag :a
                 :attrs {:id "next-selector"
                         :role "button"
                         :class "big-link"}
                 :content ["Next"]}]}
              (wrap-in-if-member-of
                (big-link (str
                           "Add a new "
                           (pretty-name entity))
                          (editor-name entity application))
                :writeable
                entity
                application)))))}
     :content
     {:tag :form
      :attrs {:id form-name :class "list"
              :action (str "{{servlet-context}}/" form-name)
              :method "POST"}
      :content
      [(csrf-widget)
       {:tag :input
        :attrs {:id "offset" :name "offset" :type "hidden"
                :value "{{params.offset|default:0}}"}}
       {:tag :input
        :attrs {:id "limit" :name "limit" :type "hidden"
                :value "{{params.limit|default:50}}"}}
       {:tag :table
        :attrs {:caption (:name (:attrs entity))}
        :content
        [(list-thead list-spec entity application)
         (list-tbody "records" list-spec entity application)
         ]}]}
     :extra-script
     (str "
          var form = document.getElementById('" form-name "');
          var ow = document.getElementById('offset');
          var lw = document.getElementById('limit');
          form.addEventListener('submit', function() {
            ow.value='0';
          });

          var prevSelector = document.getElementById('prev-selector');
          if (prevSelector != null) {
            prevSelector.addEventListener('click', function () {
              if (parseInt(ow.value)===0) {
                window.location = '{{servlet-context}}/admin';
              } else {
                ow.value=(parseInt(ow.value)-parseInt(lw.value));
                console.log('Updated offset to ' + ow.value);
                form.submit();
              }
            });
          }

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
         (apply
          merge
          (map #(assoc
                  {}
                  (keyword (path-part % entity application))
                  (form-to-template % entity application))
               forms))
         {(keyword (str "form-" (:name (:attrs entity))))
          (form-to-template nil entity application)})
       (if
         pages
         (apply
          merge
          (map #(assoc
                  {}
                  (keyword (path-part % entity application))
                  (page-to-template % entity application))
               pages))
         {(keyword (str "page-" (:name (:attrs entity))))
          (page-to-template nil entity application)})
       (if
         lists
         (apply
          merge
          (map #(assoc
                  {}
                  (keyword (path-part % entity application))
                  (list-to-template % entity application))
               lists))
         {(keyword (str "list-" (:name (:attrs entity))))
          (form-to-template nil entity application)})))))


(defn emit-entity-dt
  [entity application]
  (wrap-in-if-member-of
   {:tag :dt
    :content
    [{:tag :a
      :attrs {:href (str
                     "{{servlet-context}}/"
                     (path-part :list entity application))}
      :content [(pretty-name entity)]}]}
    :readable
    entity
    application))


(defn emit-entity-dd
  [entity application]
  (wrap-in-if-member-of
    {:tag :dd
     :content
     (apply
       vector
       (map
         (fn [d]
           (hash-map
             :tag :p
             :content (:content d)))
         (children-with-tag entity :documentation)))}
    :readable
    entity
    application))


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
         (remove
           nil?
           (flatten
             (interleave
               (map
                 #(emit-entity-dt % application)
                 first-class-entities)
               (map
                 #(emit-entity-dd % application)
                 first-class-entities)))))}}}))


(defn write-template-file
  [filename template application]
  (let [filepath (str
                  *output-path*
                  "resources/templates/auto/"
                  filename)]
    (if
      template
      (do-or-warn
       (do
         (make-parents filepath)
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
                   (emit-content content)
                   "{% endblock %}"))
               (keys template)))
             (file-footer filename application)))))
         (if
           (pos? *verbosity*)
           (*warn* "\tGenerated " filepath))
         (str filepath))
       (str "While generating " filepath)))))


(defn to-selmer-templates
  "Generate all [Selmer](https://github.com/yogthos/Selmer) templates implied
  by this ADL `application` spec."
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
             (do-or-warn
               (write-template-file
                filename
                (templates-map %)
                application))))
        (keys templates-map)))))


