(ns ^{:doc "Application Description Language: generate routes for user interface requests."
      :author "Simon Brooke"}
  adl.to-selmer-routes
  (:require [adl-support.core :refer :all]
            [adl-support.utils :refer :all]
            [adl-support.forms-support :refer :all]
            [clj-time.core :as t]
            [clj-time.format :as f]
            [clojure.java.io :refer [file make-parents writer]]
            [clojure.pprint :refer [pprint]]
            [clojure.string :as s]
            [clojure.xml :as x]
            ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; adl.to-selmer-routes: generate routes for user interface requests.
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

;;; Generally. there are two routes - one for GET, one for POST - in the
;;; generated file for each Selmer template which has been generated.

(defn file-header
  [application]
  (list
   'ns
   (symbol (str (:name (:attrs application)) ".routes.auto"))
   (str "User interface routes for " (pretty-name application)
        " auto-generated by [Application Description Language framework](https://github.com/simon-brooke/adl) at "
        (f/unparse (f/formatters :basic-date-time) (t/now)))
   (list
    :require
    '[adl-support.core :as support]
    '[adl-support.forms-support :refer :all]
    '[adl-support.rest-support :refer :all]
    '[clojure.java.io :as io]
    '[clojure.set :refer [subset?]]
    '[clojure.tools.logging :as log]
    '[clojure.walk :refer [keywordize-keys]]
    '[compojure.core :refer [defroutes GET POST]]
    '[hugsql.core :as hugsql]
    '[noir.response :as nresponse]
    '[noir.util.route :as route]
    '[ring.util.http-response :as response]
    (vector (symbol (str (:name (:attrs application)) ".layout")) :as 'l)
    (vector (symbol (str (:name (:attrs application)) ".db.core")) :as 'db)
    (vector (symbol (str (:name (:attrs application)) ".routes.manual")) :as 'm))))


(defn compose-fetch-record
  [e]
  (let
    [entity-name (singularise (:name (:attrs e)))
     warning (str
              "Error while fetching "
              entity-name
              " record")]
    (list
     'if
     (list
      'all-keys-present?
      'params (key-names e true))
     (list
      'support/do-or-log-error
      (list
       (query-name e :get)
       (symbol "db/*db*")
       'params)
      :message warning
      :error-return {:warnings [warning]})
     'params)))


(defn compose-get-menu-options
  [property application]
  ;; TODO: doesn't handle the case of type="link"
  (case (-> property :attrs :type)
    "entity" (if-let [e (child-with-tag
                        application
                        :entity
                        #(= (-> % :attrs :name)
                            (-> property :attrs :entity)))]
              (hash-map
               (keyword (-> property :attrs :name))
               (list
                'get-menu-options
                (singularise (-> e :attrs :name))
                (query-name e :search-strings)
                (query-name e :search-strings)
                (keyword (-> property :attrs :farkey))
                (list (keyword (-> property :attrs :name)) 'params)))
              {})
    "link" (list
           'do
           (list
            'comment
            "Can't yet handle link properties")
           {})
    "list" (list
           'do
           (list
            'comment
            "Can't yet handle link properties")
           {})
    (list
     'do
     (list
      'comment
      (str "Unexpected type " (-> property :atts :type)))
     {})))


(defn compose-fetch-auxlist-data
  [auxlist entity application]
  (let [p-name (-> auxlist :attrs :property)
        property (child-with-tag entity
                                 :property
                                 #(= (-> % :attrs :name) p-name))
        f-name (-> property :attrs :entity)
        farside (child-with-tag application
                                :entity
                                #(= (-> % :attrs :name) f-name))]
    (if (and (entity? entity) (entity? farside))
      (list 'if (list 'all-keys-present? 'params  (key-names entity true))
            (hash-map
             (keyword (auxlist-data-name auxlist))
             (list
              (symbol (str "db/" (list-related-query-name property entity farside)))
              'db/*db*
              {:id
               (list
                (case (-> property :attrs :type)
                  "link" :id
                  "list" (keyword (-> property :attrs :name)))
                'params)})))
      (do
        (if-not
          (entity? entity)
          (*warn*
           (str
            "Entity '"
            (-> entity :attrs :name)
            "' passed to compose-fetch-auxlist-data is a non-entity")))
        (if-not
          (entity? farside)
          (*warn*
           (str
            "Entity '"
            f-name
            "' (" farside ")
            found in compose-fetch-auxlist-data is a non-entity")))
        nil))))


(defn make-form-get-handler-content
  [f e a n]
  (list
   'let
   (vector
    'record (compose-fetch-record e))
   (list
    'reduce
    'merge
    {:error (list :warnings 'record)
     :record (list 'dissoc 'record :warnings)}
    (cons
     'list
     (concat
      (map
       #(compose-get-menu-options % a)
       (filter #(:entity (:attrs %))
               (descendants-with-tag e :property)))
      (map
       #(compose-fetch-auxlist-data % e a)
       (descendants-with-tag f :auxlist))
       (list
         (list 'if (list :error 'request)
               {:error (list :error 'request)})
         (list 'if (list :message 'request)
               {:message (list :message 'request)})))))))


(defn make-page-get-handler-content
  [f e a n]
  (list
   'let
   (vector
    'record (compose-fetch-record e))
   {:warnings (list :warnings 'record)
    :record (list 'assoc 'record :warnings nil)}))


(defn make-list-get-handler-content
  [f e a n]
  (list
   'let
   (vector
    'records
    (list
     'if
     (list
      'some
      (set (map #(keyword (-> % :attrs :name)) (all-properties e)))
      (list
       'keys 'params))
     (list
      'do
      (list
       (symbol "log/debug")
       (list
        (symbol
         (str "db/search-strings-" (:name (:attrs e)) "-sqlvec")) 'params))
      (list
       'support/do-or-log-error
       (list
        (symbol (str "db/search-strings-" (:name (:attrs e))))
        (symbol "db/*db*")
        'params)
       :message (str
                 "Error while searching "
                 (singularise (:name (:attrs e)))
                 " records")
       :error-return {:warnings [(str
                                  "Error while searching "
                                  (singularise (:name (:attrs e)))
                                  " records")]}))
     (list
      'do
      (list
       (symbol "log/debug")
       (list (symbol (str "db/list-" (:name (:attrs e)) "-sqlvec")) 'params))
      (list
       'support/do-or-log-error
       (list
        (symbol
         (str
          "db/list-"
          (:name (:attrs e))))
        (symbol "db/*db*") 'params)
       :message (str
                 "Error while fetching "
                 (singularise (:name (:attrs e)))
                 " records")
       :error-return {:warnings [(str
                                  "Error while fetching "
                                  (singularise (:name (:attrs e)))
                                  " records")]}))))
   (list
    'if
    (list :warnings 'records)
    'records
    {:records 'records})))


(defn handler-name
  "Generate the name of the appropriate handler function for form `f` of
  entity `e` of application `a` for method `m`, where `f`, `e`, and `a`
  are expected to be elements and `m` is expected to be one of the keywords
  `:put` `:get`."
  [f e a m]
  (str (s/lower-case (name m)) "-" (path-part f e a)))


(defn make-get-handler
  [f e a]
  (let [n (handler-name f e a :get)]
    (list
     'defn
     (symbol n)
     (vector 'request)
     (list 'let (vector
                 'params
                 (list 'support/massage-params 'request))
           (list
            'l/render
            (list 'support/resolve-template (str (path-part f e a) ".html"))
            (list 'merge
                  {:title (capitalise (:name (:attrs f)))
                   :params  (list 'merge (property-defaults e) 'params)}
                  (case (:tag f)
                    :form (make-form-get-handler-content f e a n)
                    :page (make-page-get-handler-content f e a n)
                    :list (make-list-get-handler-content f e a n))))))))


(defn make-form-post-handler-content
  ;; Literally the only thing the post handler has to do is to
  ;; generate the database store operation. Then it can hand off
  ;; to the get handler.
  [f e a n]
  (let
    [create-name (query-name e :create)
     update-name (query-name e :update)]
    (list
      'let
      (vector
        'insert-params (list
                         'prepare-insertion-params
                         'params
                         (set
                           (map
                             #(-> % :attrs :name)
                             (insertable-properties e))))
        'result
        (list
          'valid-user-or-forbid
          (list
            'with-params-or-error
            (list
              'if
              (list 'all-keys-present? 'params (key-names e true))
              (list
                'do-or-server-fail
                (list
                  update-name
                  'db/*db*
                  'insert-params)
                200)
              (list
                'do-or-server-fail
                (list
                  create-name
                  'db/*db*
                  'insert-params)
                201))
            'params
            (set
              (map
                #(keyword (:name (:attrs %)))
                (required-properties e))))
          'request))
      (list
        (symbol (handler-name f e a :get))
        (list 'merge
              (list
                'assoc
                'request
                :params
                (list
                  'merge
                  'params
                  'result))
              (list 'case (list :status 'result)
                    200 {:message "Record stored"}
                    201 (list 'try
                          (list 'hash-map
                                :params
                                (list 'merge 'params
                            (list :body 'result))
                                :message
                                (list 'str "Record created")(list :body 'result))
                          (list
                            'catch 'Exception 'x
                            {:message "Record created"
                             :error "Exception while reading returned key"}))
                    {:error (list :body 'result)}))))))


(defn make-post-handler
  [f e a]
  (let [n (handler-name f e a :post)]
    (list
     'defn
     (symbol n)
     (vector 'request)
     (case
       (:tag f)
       (:page :list) (list (symbol (handler-name f e a :get)) 'request)
       :form (list
              'let
              (vector
               'params
               (list 'support/massage-params 'request))
              (make-form-post-handler-content f e a n))))))


;; (def a (x/parse "../youyesyet/youyesyet.canonical.adl.xml"))
;; (def e (child-with-tag a :entity))
;; (def f (child-with-tag e :form))
;; (def n (handler-name f e a :post))
;; (make-post-handler f e a)
;; (vector
;;  'p
;;  (list 'merge
;;        {:offset 0 :limit 25}
;;        (list 'support/massage-params (list :params 'r))))
;; (make-get-handler f e a)


(defn make-route
  "Make a route for method `m` to request the resource with name `n`."
  [m n]
  (list
   (symbol (s/upper-case (name m)))
   (str "/" n)
   'request
   (list
    'route/restricted
    (list
     'apply
     (list 'resolve-handler (str (s/lower-case (name m)) "-" n))
     (list 'list 'request)))))


(defn make-defroutes
  [application]
  (let [routes (flatten
                (map
                 (fn [e]
                   (map
                    (fn [c]
                      (path-part c e application))
                    (filter (fn [c] (#{:form :list :page} (:tag c))) (children e))))
                 (children-with-tag application :entity)))]
    (cons
     'defroutes
     (cons
      'auto-selmer-routes
      (cons
       '(GET
         "/admin"
         request
         (route/restricted
          (apply (resolve-handler "index") (list request))))
       (interleave
        (map
         (fn [r] (make-route :get r))
         (sort routes))
        (map
         (fn [r] (make-route :post r))
         (sort routes))))))))


(defn generate-handler-resolver
  "Dodgy, dodgy, dodgy. Generate code which will look up functions in the
  manual and in this namespace. I'm sure someone who really knew what they
  were doing could write this more elegantly."
  [application]
  (list
   'defn
   'raw-resolve-handler
   "Prefer the manually-written version of the handler with name `n`, if it exists, to the automatically generated one"
   (vector 'n)
   (list 'try
         (list 'eval (list 'symbol (list 'str (:name (:attrs application)) ".routes.manual/" 'n)))
         (list 'catch
               'Exception '_
               (list 'eval
                     (list 'symbol
                           (list 'str (:name (:attrs application)) ".routes.auto/" 'n)))))))


(defn make-handlers
  [e application]
  (doall
   (map
    (fn [c]
      ;; do all get handlers before post handlers, so that the post
      ;; handlers can call the get handlers.
      (pprint (make-get-handler c e application))
      (println "\n")
      (pprint (make-post-handler c e application))
      (println "\n"))
    (filter (fn [c] (#{:form :list :page} (:tag c))) (children e)))))


(defn to-selmer-routes
  [application]
  (let [filepath (str
                  *output-path*
                  "src/clj/"
                  (:name (:attrs application))
                  "/routes/auto.clj")
        entities (sort
                  #(compare (:name (:attrs %1))(:name (:attrs %2)))
                  (children-with-tag application :entity))]
    (make-parents filepath)
    (do-or-warn
     (with-open [output (writer filepath)]
       (binding [*out* output]
         (pprint (file-header application))
         (println)
         (pprint '(defn index
                    [r]
                    (l/render
                     (support/resolve-template
                      "application-index.html")
                     (:session r)
                     {:title "Administrative menu"})))
         (println)
         (doall
          (map
           #(make-handlers % application)
           entities))
         (pprint
          (generate-handler-resolver application))
         (println)
         (pprint '(def resolve-handler
                    (memoize raw-resolve-handler)))
         (println)
         (pprint (make-defroutes application))
         (println)))
     (if
       (pos? *verbosity*)
       (*warn* (str "\tGenerated " filepath))))))

