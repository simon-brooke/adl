(ns ^{:doc "Application Description Language - command line invocation."
      :author "Simon Brooke"}
  adl.main
  (:require [adl.to-cache :as c]
            [adl.to-hugsql-queries :as h]
            [adl.to-json-routes :as j]
            [adl.to-psql :as p]
            [adl.to-selmer-routes :as s]
            [adl.to-selmer-templates :as t]
            [adl-support.core :refer [*warn*]]
            [adl-support.print-usage :refer [print-usage]]
            [adl-support.utils :refer :all]
            [clojure.java.io :refer [as-file file make-parents resource]]
            [clojure.string :refer [includes? join split]]
            [clojure.tools.cli :refer [parse-opts]]
            [clojure.xml :as x]
            [environ.core :refer [env]]
            [saxon :as sax])
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
  "Command-line interface options"
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
    :default 0]])


(defn usage
  "Show a usage message. `parsed-options` should be options as
  parsed by [clojure.tools.cli](https://github.com/clojure/tools.cli)"
  [parsed-options]
  (print-usage
    "adl"
    parsed-options
    {"adl-file" "An XML file conforming to the ADL DTD"}))


(def adl->canonical
  "A function which takes ADL text as its single argument and returns
  canonicalised ADL text as its result."
  (sax/compile-xslt (resource "transforms/adl2canonical.xslt")))


(defn canonicalise
  "Canonicalise the ADL document indicated by this `filepath` (if it is not
  already canonical) and return a path to the canonical version."
  [filepath]
  (if
    ;; if it says it's canonical, we'll just believe it.
    (includes? filepath ".canonical.")
    filepath
    (let
      [parts (split (.getName (as-file filepath)) #"\.")
       outpath (file
                 *output-path*
                 (join
                   "."
                   (cons (first parts) (cons "canonical" (rest parts)))))]
      (spit outpath (adl->canonical (sax/compile-xml (slurp filepath))))
      (.getAbsolutePath outpath))))


(defn process
  "Process these parsed `options`."
  [options]
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
           (let [application (x/parse (canonicalise %))]
             (c/to-cache application)
             (h/to-hugsql-queries application)
             (j/to-json-routes application)
             (p/to-psql application)
             (s/to-selmer-routes application)
             (t/to-selmer-templates application))
           (*warn* (str "ERROR: File not found: " %)))
        (:arguments options))))))


(defn -main
  "Parses options and arguments. Expects as args the path-name of one or
  more ADL files."
  [& args]
  (let [options (parse-opts args cli-options)]
    (cond
      (empty? args)
      (usage options)
      (seq (:errors options))
      (do
        (doall
          (map
            println
            (:errors options)))
        (usage options))
      (-> options :options :help)
      (usage options)
      true
      (process options))))



