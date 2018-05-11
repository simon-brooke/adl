(ns adl.utils
  (:require [clojure.string :as s]
            [clojure.xml :as x]
            [adl.validator :refer [valid-adl? validate-adl]]))



(defn children
  "Return the children of this `element`; if `predicate` is passed, return only those
  children satisfying the predicate."
  ([element]
   (if
     (keyword? (:tag element)) ;; it has a tag; it seems to be an XML element
     (:content element)))
  ([element predicate]
     (remove ;; there's a more idionatic way of doing remove-nil-map, but for the moment I can't recall it.
       nil?
       (map
         #(if (predicate %) %)
         (children element)))))


(defn singularise [string]
  (s/replace (s/replace (s/replace string #"_" "-") #"s$" "") #"ie$" "y"))


(defn link-table?
  "Return true if this `entity` represents a link table."
  [entity]
  (let [properties (children entity #(= (:tag %) :property))
        links (filter #(-> % :attrs :entity) properties)]
    (= (count properties) (count links))))

(defn read-adl [url]
  (let [adl (x/parse url)
        valid? (valid-adl? adl)]
    adl))
;;     (if valid? adl
;;       (throw (Exception. (str (validate-adl adl)))))))

(defn key-names [entity-map]
  (remove
    nil?
    (map
      #(:name (:attrs %))
      (vals (:content (:key (:content entity-map)))))))


(defn has-primary-key? [entity-map]
  (> (count (key-names entity-map)) 0))


(defn has-non-key-properties? [entity-map]
  (>
    (count (vals (:properties (:content entity-map))))
    (count (key-names entity-map))))


(defn attributes
  "Return the attributes of this `element`; if `predicate` is passed, return only those
  attributes satisfying the predicate."
  ([element]
   (if
     (keyword? (:tag element)) ;; it has a tag; it seems to be an XML element
     (:attrs element)))
  ([element predicate]
     (remove ;; there's a more idionatic way of doing remove-nil-map, but for the moment I can't recall it.
       nil?
       (map
         #(if (predicate %) %)
         (:attrs element)))))



;; (read-adl "../youyesyet/stripped.adl.xml")
