(ns ^{:doc "Application Description Language: generate RING routes for REST requests."
      :author "Simon Brooke"}
  adl.to-json-routes
  (:require [adl-support.utils :refer :all]
            [adl.to-hugsql-queries :refer [queries]]
            [clj-time.core :as t]
            [clj-time.format :as f]
            [clojure.java.io :refer [file make-parents writer]]
            [clojure.pprint :refer [pprint]]
            [clojure.string :as s]
            [clojure.xml :as x]))

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

;;; The overall structure of this has quite closely to follow the structure of
;;; to-hugsql-queries, because essentially we need one JSON entry point to wrap
;;; each query.

;;; TODO: memoisation of handlers probably doesn't make sense, because every request
;;; will be different. I don't think we can memoise HugSQL, at least not without
;;; hacking the library (might be worth doing that and contributing a patch).
;;; So the solution may be to an intervening namespace 'cache', which has one
;;; memoised function for each hugsql query.

(defn file-header [application]
  (list
    'ns
    (symbol (str (safe-name (:name (:attrs application))) ".routes.auto-json"))
    (str "JSON routes for " (:name (:attrs application))
         " auto-generated by [Application Description Language framework](https://github.com/simon-brooke/adl) at "
         (f/unparse (f/formatters :basic-date-time) (t/now)))
    (list
      :require
      '[adl-support.core :as support]
      '[clojure.core.memoize :as memo]
      '[clojure.java.io :as io]
      '[clojure.tools.logging :as log]
      '[compojure.core :refer [defroutes GET POST]]
      '[hugsql.core :as hugsql]
      '[noir.response :as nresponse]
      '[noir.util.route :as route]
      '[ring.util.http-response :as response]
      (vector (symbol (str (safe-name (:name (:attrs application))) ".db.core")) :as 'db))))


(defn declarations [handlers-map]
  (cons 'declare (sort (map #(symbol (name %)) (keys handlers-map)))))


(defn generate-handler-body
  "Generate and return the function body for the handler for this `query`."
  [query]
  (let [action (list
                 (symbol (str "db/" (:name query)))
                 'db/*db*
                 (list 'support/massage-params
                       'params
                       'form-params
                       (key-names (:entity query))))]
    (list
     [{:keys ['params 'form-params]}]
     (case
       (:type query)
       (:delete-1 :update-1)
       (list
         action
         `(log/debug (str ~(:name query) " called with params " ~'params "."))
         '(response/found "/"))
       (list
         'let
         (vector 'result action)
         `(log/debug (~(symbol (str "db/" (:name query) "-sqlvec")) ~'params))
         `(log/debug (str ~(str "'" (:name query) "' with params ") ~'params " returned " (count ~'result) " records."))
         (list 'response/ok 'result))))))


(defn generate-handler-src
  "Generate and return the handler for this `query`."
  [handler-name query-map method doc]
  (hash-map
    :method method
    :src (remove
           nil?
           (if
             (or
               (zero? (volatility (:entity query-map)))
               (#{:delete-1 :insert-1 :update-1} (:type query-map)))
             (concat
               (list
                 'defn
                 handler-name
                 (str "Auto-generated method to " doc))
               (generate-handler-body query-map))
             (concat
               (list
                 'def
                 handler-name
                 (list
                   'memo/ttl
                   (cons 'fn (generate-handler-body query-map))
                   :ttl/threshold
                   (* (volatility (:entity query-map)) 1000))))))))


(defn handler
  "Generate declarations for handlers from query with this `query-key` in this `queries-map`
  taken from within this `application`. This method must follow the structure of
  `to-hugsql-queries/queries` quite closely, because we must generate the same names."
  [query-key queries-map application]
  (let [query (query-key queries-map)
        handler-name (symbol (name query-key))]
    (hash-map
      (keyword handler-name)
      (merge
        {:name handler-name
         :route (str "/json/" handler-name)}
        (case
          (:type query)
          :delete-1
          (generate-handler-src
            handler-name query :post
            (str "delete one record from the `"
                 (-> query :entity :attrs :name)
                 "` table. Expects the following key(s) to be present in `params`: `"
                 (-> query :entity key-names)
                 "`."))
          :insert-1
          (generate-handler-src
            handler-name query :post
            (str "insert one record to the `"
                 (-> query :entity :attrs :name)
                 "` table. Expects the following key(s) to be present in `params`: `"
                 (pr-str
                   (map
                     #(keyword (:name (:attrs %)))
                     (-> query :entity insertable-properties )))
                 "`. Returns a map containing the keys `"
                 (-> query :entity key-names)
                 "` identifying the record created."))
          :update-1
          (generate-handler-src
            handler-name query :post
            (str "update one record in the `"
                 (-> query :entity :attrs :name)
                 "` table. Expects the following key(s) to be present in `params`: `"
                 (pr-str
                   (distinct
                     (sort
                       (map
                         #(keyword (:name (:attrs %)))
                         (flatten
                           (cons
                             (-> query :entity key-properties)
                             (-> query :entity insertable-properties)))))))
                 "`."))
          :select-1
          (generate-handler-src
            handler-name query :get
            (str "select one record from the `"
                 (-> query :entity :attrs :name)
                 "` table. Expects the following key(s) to be present in `params`: `"
                 (-> query :entity key-names)
                 "`. Returns a map containing the following keys: `"
                 (map #(keyword (:name (:attrs %))) (-> query :entity all-properties))
                 "`."))
          :select-many
          (generate-handler-src
            handler-name query :get
            (str "select all records from the `"
                 (-> query :entity :attrs :name)
                 "` table. If the keys `(:limit :offset)` are present in the request then they will be used to page through the data. Returns a sequence of maps each containing the following keys: `"
                 (pr-str
                   (map
                     #(keyword (:name (:attrs %)))
                     (-> query :entity all-properties)))
                 "`."))
          :text-search
          (generate-handler-src
            handler-name query :get
            (str "select all records from the `"
                 (-> query :entity :attrs :name)
                 ;; TODO: this doc-string is out of date
                 "` table with any text field matching the value of the key `:pattern` which should be in the request. If the keys `(:limit :offset)` are present in the request then they will be used to page through the data. Returns a sequence of maps each containing the following keys: `"
                 (pr-str
                   (map
                     #(keyword (:name (:attrs %)))
                     (-> query :entity all-properties)))
                 "`."))
          (:select-many-to-many
           :select-one-to-many)
          (hash-map :method :get
                    :src (list 'defn handler-name [{:keys ['params]}]
                               (list 'do (list (symbol (str "db/" (:name query))) 'params))))
          ;; default
          (hash-map
            :src
            (str ";; don't know what to do with query `" :key "` of type `" (:type query) "`.")))))))


(defn defroutes [handlers-map]
  "Generate JSON routes for all queries implied by this ADL `application` spec."
  (cons
    'defroutes
    (cons
      'auto-rest-routes
      (map
        #(let [handler (handlers-map %)]
           (list
             (symbol (s/upper-case (name (:method handler))))
             (str "/json/auto/" (safe-name (:name handler)))
             'request
              (list
                'route/restricted
               (list (:name handler) 'request))))
        (sort
          (keys handlers-map))))))


(defn make-handlers-map
  [application]
  (reduce
    merge
    {}
    (map
      (fn [e]
        (let [qmap (queries application e)]
          (reduce
            merge
            {}
            (map
              (fn [k]
                (handler k qmap application))
              (keys qmap)))))
      (children-with-tag application :entity))))


(defn to-json-routes
  [application]
  (let [handlers-map (make-handlers-map application)
        filepath (str *output-path* "src/clj/" (:name (:attrs application)) "/routes/auto_json.clj")]
    (make-parents filepath)
    (try
      (with-open [output (writer filepath)]
        (binding [*out* output]
          (pprint (file-header application))
          (println)
          (doall
            (map
              (fn [h]
                (pprint (:src (handlers-map h)))
                (println)
                h)
              (sort (keys handlers-map))))
          (pprint (defroutes handlers-map))))
      (if (> *verbosity* 0)
        (println (str "\tGenerated " filepath)))
      (catch
        Exception any
        (println
          (str
            "ERROR: Exception "
            (.getName (.getClass any))
            (.getMessage any)
            " while printing "
            filepath))))))


