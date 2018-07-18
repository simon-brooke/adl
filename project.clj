(defproject adl "1.4.2-SNAPSHOT"
  :description "An application to transform an ADL application specification document into skeleton code for a Clojure web-app"
  :url "http://example.com/FIXME"
  :license {:name "GNU General Public License,version 2.0 or (at your option) any later version"
            :url "https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html"}
  :dependencies [[adl-support "0.1.0-SNAPSHOT"]
                 [org.clojure/clojure "1.8.0"]
                 [org.clojure/math.combinatorics "0.1.4"]
                 [org.clojure/tools.cli "0.3.7"]
                 [bouncer "1.0.1"]
                 [environ "1.1.0"]
                 [hiccup "1.0.5"]]
  :aot  [adl.main]
  :main adl.main
  :plugins [[lein-codox "0.10.3"]])
