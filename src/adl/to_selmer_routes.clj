(ns ^{:doc "Application Description Language: generate routes for user interface requests."
      :author "Simon Brooke"}
  adl.to-selmer-routes
  (:require [clojure.java.io :refer [file make-parents writer]]
            [clojure.pprint :refer [pprint]]
            [clojure.string :as s]
            [clojure.xml :as x]
            [clj-time.core :as t]
            [clj-time.format :as f]
            [adl.utils :refer :all]))

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

;;; Generally. there's one route in the generated file for each Selmer template which has been generated.

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
      '[clojure.java.io :as io]
      '[compojure.core :refer [defroutes GET POST]]
      '[hugsql.core :as hugsql]
      '[noir.response :as nresponse]
      '[noir.util.route :as route]
      '[ring.util.http-response :as response]
      (vector (symbol (str (:name (:attrs application)) ".layout")) :as 'l)
      (vector (symbol (str (:name (:attrs application)) ".db.core")) :as 'db)
      (vector (symbol (str (:name (:attrs application)) ".routes.manual")) :as 'm))))

(defn make-handler
  [f e a]
  (let [n (path-part f e a)]
    (list
      'defn
      (symbol n)
      (vector 'r)
      (list 'let (vector 'p (list :form-params 'r))
            (list
              'l/render
              (list 'resolve-template (str n ".html"))
              (merge
                {:title (capitalise (:name (:attrs f)))
                 :params  'p}
                (case (:tag f)
                  (:form :page)
                  {:record
                   (list
                     (symbol
                       (str "db/get-" (singularise (:name (:attrs e)))))
                     'p)}
                  :list
                  {:records
                   (list
                     (symbol
                       (str
                         "db/search-strings-"
                         (singularise (:name (:attrs e)))))
                     'p)})))))))

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
             "/index"
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


(defn to-selmer-routes
  [application]
  (let [filename (str *output-path* (:name (:attrs application)) "/routes/auto.clj")]
    (make-parents filename)
    (with-open [output (writer filename)]
      (binding [*out* output]
        (pprint (file-header application))
        (println)
        (pprint '(defn raw-resolve-template [n]
                   (if
                     (.exists (io/as-file (str "resources/templates/" n)))
                     n
                     (str "auto/" n))))
        (println)
        (pprint '(def resolve-template (memoize raw-resolve-template)))
        (println)
        (pprint '(defn index
                   [r]
                   (l/render
                     (resolve-template
                       "application-index.html")
                     {:title "Administrative menu"})))
        (println)
        (doall
          (map
            (fn [e]
              (doall
                (map
                  (fn [c]
                    (pprint (make-handler c e application))
                    (println))
                  (filter (fn [c] (#{:form :list :page} (:tag c))) (children e)))))
            (children-with-tag application :entity)))
        (pprint
          (generate-handler-resolver application))
        (println)
        (pprint '(def resolve-handler
                   (memoize raw-resolve-handler)))
        (println)
        (pprint (make-defroutes application))
        (println)))))

