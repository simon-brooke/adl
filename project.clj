(defproject adl "1.4.1-SNAPSHOT"
  :description "An application to transform an ADL application specification document into skeleton code for a Clojure web-app"
  :url "http://example.com/FIXME"
  :license {:name "GNU General Public License,version 2.0 or (at your option) any later version"
            :url "https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html"}
  :dependencies [[org.clojure/clojure "1.8.0"]
                 [org.clojure/math.combinatorics "0.1.4"]
                 [bouncer "1.0.1"]
                 [hiccup "1.0.5"]]
  :aot  [adl.main]
  :main adl.main
  :plugins [[lein-codox "0.10.3"]])
