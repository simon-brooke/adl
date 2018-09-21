(defproject adl "1.4.6-SNAPSHOT"
  :description "An application to transform an ADL application specification
  document into skeleton code for a Clojure web-app"
  :url "https://github.com/simon-brooke/adl"
  :license {:name "GNU Lesser General Public License, version 3.0 or (at your option) any later version"
            :url "https://www.gnu.org/licenses/lgpl-3.0.en.html"}

  :dependencies [[adl-support "0.1.4"]
                 [bouncer "1.0.1"]
                 [clojure-saxon "0.9.4"]
                 [environ "1.1.0"]
                 [hiccup "1.0.5"]
                 [org.clojure/clojure "1.8.0"]
                 [org.clojure/math.combinatorics "0.1.4"]
                 [org.clojure/tools.cli "0.3.7"]]

  :aot  [adl.main]

  :main adl.main

  :plugins [[lein-codox "0.10.3"]
            [lein-kibit "0.1.6"]
            [lein-release "1.0.5"]
            ;; [uncomplexor "0.1.0-SNAPSHOT"]
            ]

  :codox {:metadata {:doc "FIXME: write docs"}
          :output-path "docs"}

  :deploy-repositories [["releases" :clojars]
                        ["snapshots" :clojars]]

  ;; `lein release` doesn't play nice with `git flow release`. Run `lein release` in the
  ;; `develop` branch, then merge the release tag into the `master` branch.

  :release-tasks [["vcs" "assert-committed"]
                  ["clean"]
                  ["test"]
                  ["codox"]
                  ["change" "version" "leiningen.release/bump-version" "release"]
                  ["vcs" "commit"]
                  ;; ["vcs" "tag"] -- not working, problems with secret key
                  ["uberjar"]
                  ["install"]
                  ;; ["deploy" "clojars"] -- also not working
                  ["change" "version" "leiningen.release/bump-version"]
                  ["vcs" "commit"]])
