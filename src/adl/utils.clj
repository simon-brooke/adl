(ns adl.utils
  (:require [clojure.string :as s]))

(defn singularise [string]
  (s/replace (s/replace (s/replace string #"_" "-") #"s$" "") #"ie$" "y"))

(defn is-link-table?
  [entity-map]
  (let [properties (-> entity-map :content :properties vals)
        links (filter #(-> % :attrs :entity) properties)]
    (= (count properties) (count links))))
