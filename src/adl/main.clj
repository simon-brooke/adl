(ns ^{:doc "Application Description Language - command line invocation."
      :author "Simon Brooke"}
  adl.main
  (:require [adl-support.utils :refer :all]
            [adl.to-hugsql-queries :as h]
            [adl.to-json-routes :as j]
            [adl.to-psql :as p]
            [adl.to-selmer-routes :as s]
            [adl.to-selmer-templates :as t]
            [clojure.java.io :refer [make-parents]]
            [clojure.string :refer [join]]
            [clojure.tools.cli :refer [parse-opts]]
            [clojure.xml :as x]
            [environ.core :refer [env]])
  (:gen-class))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; adl.main
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

(def cli-options
  [["-a" "--abstract-key-name-convention [string]" "the abstract key name convention to use for generated key fields (TODO: not yet implemented)"
    :default "id"]
   ["-h" "--help" "Show this message"
    :default false]
   ["-l" "--locale [LOCALE]" "set the locale to generate"
    :default (env :lang)]
   ["-p" "--path [PATH]" "The path under which generated files should be written"
    :default "generated"]
   ["-v" "--verbosity [LEVEL]" nil "Verbosity level - integer value required"
    :parse-fn #(Integer/parseInt %)
    :default 0]
   ])


(defn- doc-part
  "An `option` in cli-options comprises a sequence of strings followed by
  keyword/value pairs. Return all the strings before the first keyword."
  [option]
  (if
    (keyword? (first option)) nil
    (cons (first option) (doc-part (rest option)))))

(defn map-part
  "An `option` in cli-options comprises a sequence of strings followed by
  keyword/value pairs. Return the keyword/value pairs as a map."
  [option]
  (cond
    (empty? option) nil
    (keyword? (first option)) (apply hash-map option)
    true
    (map-part (rest option))))

(defn print-usage []
  (println
    (join
      "\n"
      (flatten
        (list
          (join
            (list
              "Usage: java -jar adl-"
              (or (System/getProperty "adl.version") "[VERSION]")
              "-SNAPSHOT-standalone.jar -options [adl-file]"))
          "where options include:"
          (map
            #(let
               [doc-part (doc-part %)
                default (:default (map-part %))
                default-string (if default (str "; (default: " default ")"))]
               (str "\t" (join ", " (butlast doc-part)) ": " (last doc-part) default-string))
            cli-options))))))


(defn -main
  "Expects as arg the path-name of an ADL file."
  [& args]
  (let [options (parse-opts args cli-options)]
    (cond
      (empty? args)
      (print-usage)
      (not (empty? (:errors options)))
      (do
        (doall
          (map
            println
            (:errors options)))
        (print-usage))
      (-> options :options :help)
      (print-usage)
      true
      (do
        (let [p (:path (:options options))
              op (if (.endsWith p "/") p (str p "/"))]
          (binding [*output-path* op
                    *locale* (-> options :options :locale)
                    *verbosity* (-> options :options :verbosity)]
            (make-parents *output-path*)
            (doall
              (map
                #(if
                   (.exists (java.io.File. %))
                   (let [application (x/parse %)]
                     (h/to-hugsql-queries application)
                     (j/to-json-routes application)
                     (p/to-psql application)
                     (s/to-selmer-routes application)
                     (t/to-selmer-templates application))
                   (println (str "ERROR: File not found: " %)))
                (-> options :arguments)))))))))



