(ns ^{:doc "Application Description Language: generate routes for user interface requests."
      :author "Simon Brooke"}
  adl.to-selmer-routes
  (:require [adl-support.core :refer [*warn*]]
            [adl-support.utils :refer :all]
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

;;; Generally. there's one route in the generated file for each Selmer
;;; template which has been generated.

;;; TODO: there must be some more idiomatic way of generating all these
;;; functions.

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


(defn make-form-handler-content
  [f e a n]
  (let [warning (list 'str (str "Error while fetching " (singularise (:name (:attrs e))) " record ") 'params)]
    ;; TODO: as yet makes no attempt to save the record
    (list 'let
          (vector
            'record (list
                      'support/do-or-log-error
                      ;;(list 'if (list 'subset? (key-names e) (list 'set (list 'keys 'params)))
                            (list
                              (symbol
                                (str "db/get-" (singularise (:name (:attrs e)))))
                              (symbol "db/*db*")
                              'params)
                      ;;)
                      :message warning
                      :error-return {:warnings [warning]}))
          (reduce
            merge
            {:error (list :warnings 'record)
             :record (list 'dissoc 'record :warnings)}
            (map
              (fn [property]
                (hash-map
                  (keyword (-> property :attrs :name))
                  (list
                    'flatten
                    (list
                      'remove
                      'nil?
                      (list
                        'list
                        ;; Get the current value of the property, if it's an entity
                        (if (= (-> property :attrs :type) "entity")
                          (list 'support/do-or-log-error
                                (list
                                  (symbol
                                    (str "db/get-" (singularise (:entity (:attrs property)))))
                                  (symbol "db/*db*")
                                  (hash-map (keyword (-> property :attrs :farkey))
                                            (list (keyword (-> property :attrs :name)) 'record)))
                                :message (str "Error while fetching "
                                              (singularise (:entity (:attrs property)))
                                              " record " (hash-map (keyword (-> property :attrs :farkey))
                                            (list (keyword (-> property :attrs :name)) 'record)))))
                        ;;; and the potential values of the property
                        (list 'support/do-or-log-error
                              (list (symbol (str "db/list-" (:entity (:attrs property)))) (symbol "db/*db*"))
                              :message (str "Error while fetching "
                                            (singularise (:entity (:attrs property)))
                                            " list")))))))
              (filter #(:entity (:attrs %))
                      (descendants-with-tag e :property)))))))


(defn make-page-handler-content
  [f e a n]
  (let [warning (str "Error while fetching " (singularise (:name (:attrs e))) " record")]
    (list 'let
          (vector 'record (list
                           'support/handler-content-log-error
                           (list 'if (list 'subset? (list 'keys 'p) (key-names e)) []
                                 (list
                                  (symbol
                                   (str "db/get-" (singularise (:name (:attrs e)))))
                                  (symbol "db/*db*")
                                  'params))
                           :message warning
                           :error-return {:warnings [warning]}))
           {:warnings (list :warnings 'record)
            :record (list 'assoc 'record :warnings nil)})))


(defn make-list-handler-content
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
          (list 'keys 'params))
        (list 'do
              (list (symbol "log/debug") (list (symbol (str "db/search-strings-" (:name (:attrs e)) "-sqlvec")) 'params))
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
        (list 'do
              (list (symbol "log/debug") (list (symbol (str "db/list-" (:name (:attrs e)) "-sqlvec")) 'params))
              (list
                'support/do-or-log-error
                (list
                  (symbol
                    (str
                      "db/list-"
                      (:name (:attrs e))))
                  (symbol "db/*db*") {})
                :message (str
                           "Error while fetching "
                           (singularise (:name (:attrs e)))
                           " records")
                :error-return {:warnings [(str
                                            "Error while fetching "
                                            (singularise (:name (:attrs e)))
                                            " records")]}))))
      (list 'if
            (list :warnings 'records)
            'records
            {:records 'records})))


(defn make-handler
  [f e a]
  (let [n (path-part f e a)]
    (list
      'defn
      (symbol n)
      (vector 'request)
      (list 'let (vector
                   'params
                   (list 'support/massage-params
                         (list 'keywordize-keys (list :params 'request))
                         (list 'keywordize-keys (list :form-params 'request))
                         (key-names e true)))
            (list
              'l/render
              (list 'support/resolve-template (str n ".html"))
              (list 'merge
                    {:title (capitalise (:name (:attrs f)))
                     :params  'params}
                    (case (:tag f)
                      :form (make-form-handler-content f e a n)
                      :page (make-page-handler-content f e a n)
                      :list (make-list-handler-content f e a n))))))))

;; (def a (x/parse "../youyesyet/youyesyet.canonical.adl.xml"))
;; (def e (child-with-tag a :entity))
;; (def f (child-with-tag e :form))
;; (def n (path-part f e a))
;; (make-handler f e a)
;; (vector
;;  'p
;;  (list 'merge
;;        {:offset 0 :limit 25}
;;        (list 'support/massage-params (list :params 'r))))
;; (make-handler f e a)


(defn make-route
  "Make a route for method `m` to request the resource with name `n`."
  [m n]
  (list
   m
   (str "/" n)
   'request
   (list
    'route/restricted
    (list
     'apply
     (list 'resolve-handler n)
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
         (fn [r] (make-route 'GET r))
         (sort routes))
        (map
         (fn [r] (make-route 'POST r))
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
      (pprint (make-handler c e application))
      (println))
    (filter (fn [c] (#{:form :list :page} (:tag c))) (children e)))))


(defn to-selmer-routes
  [application]
  (let [filepath (str *output-path* "src/clj/" (:name (:attrs application)) "/routes/auto.clj")]
    (make-parents filepath)
    (try
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
            (sort
             #(compare (:name (:attrs %1))(:name (:attrs %2)))
             (children-with-tag application :entity))))
          (pprint
           (generate-handler-resolver application))
          (println)
          (pprint '(def resolve-handler
                     (memoize raw-resolve-handler)))
          (println)
          (pprint (make-defroutes application))
          (println)))
      (if (> *verbosity* 0)
        (*warn* (str "\tGenerated " filepath)))
      (catch
        Exception any
        (*warn*
         (str
          "ERROR: Exception "
          (.getName (.getClass any))
          (.getMessage any)
          " while printing "
          filepath))))))
