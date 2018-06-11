(ns ^{:doc "Application Description Language - command line invocation."
      :author "Simon Brooke"}
  adl.main
  (:require [adl.utils :refer :all]
            [adl.to-hugsql-queries :as h]
            [adl.to-json-routes :as j]
            [adl.to-selmer-routes :as s]
            [adl.to-selmer-templates :as t]
            [clojure.xml :as x])
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

(defn print-usage [_]
  (println "Argument should be a pathname to an ADL file"))

(defn -main
  "Expects as arg the name of the git hook to be handled, followed by the arguments to it"
  [& args]
  (cond
    (empty? args)
    (print-usage args)
    (.exists (java.io.File. (first args)))
    (let [application (x/parse (first args))]
      (h/to-hugsql-queries application)
      (j/to-json-routes application)
      (s/to-selmer-routes application)
      (t/to-selmer-templates application))))

