(ns adl.validator-test
  (:require [clojure.java.io :refer [writer]]
            [clojure.test :refer :all]
            [clojure.xml :refer [parse]]
            [adl.validator :refer :all]
            [bouncer.core :refer [valid?]]))

;; OK, so where we're up to: documentation breaks validation of the
;; element that contains it if the documentation is non-empty.

(deftest validator-documentation-only
  (testing "validation of a bare documentation element"
    (let [xml {:tag :documentation,
               :content ["This is a very simple test document just to exercise validator and generators."]}
          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml documentation-validations))]
      (is (= actual expected))))
  (testing "validation of empty documentation within application element"
    (let [xml {:tag
               :application,
               :attrs {:version "0.0.1",
                       :name "test1"},
               :content [{:tag :documentation,
                          :attrs nil,
                          :content []}]}
          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml application-validations))]
      (is (= actual expected))))
  (testing "validation of non-empty documentation within application element"
    (let [xml {:tag :application,
               :attrs {:version "0.0.1",
                       :name "test1"},
               :content [{:tag :documentation,
                          :attrs nil,
                          :content ["This is a very simple test document just to exercise validator and generators."]}]}
          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml application-validations))]
      (is (= actual expected))))
  (testing "validation of file `documentation-only.adl.xml`."
    (let [xml (parse "resources/test/documentation-only.adl.xml")
          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml application-validations))]
      (is (= actual expected)))))

(deftest validator-content
  (testing "Validation of content element (has text in PCDATA positions)"
    (let [xml {:tag :content,
               :attrs nil,
               :content
               [{:tag :head,
                 :attrs nil,
                 :content
                 [{:tag :h:meta,
                   :attrs
                   {:content "Application Description Language framework",
                    :name "generator",
                    :xmlns "http://www.w3.org/1999/xhtml"},
                   :content nil}]}
                {:tag :top,
                 :attrs nil,
                 :content
                 [{:tag :h:h1,
                   :attrs {:xmlns "http://www.w3.org/1999/xhtml"},
                   :content ["Test 1"]}]}
                {:tag :foot,
                 :attrs nil,
                 :content
                 [{:tag :h:p,
                   :attrs {:class "footer", :xmlns "http://www.w3.org/1999/xhtml"},
                   :content ["That's all folks!"]}]}]}
          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml content-validations))]
      (is (= actual expected)))))

(deftest validator-head
  (testing "Validation of head element"
    (let [xml {:tag :head,
               :attrs nil,
               :content
               [{:tag :h:meta,
                 :attrs
                 {:content "Application Description Language framework",
                  :name "generator",
                  :xmlns "http://www.w3.org/1999/xhtml"},
                 :content nil}]}
          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml head-validations))]
      (is (= actual expected)))))

(deftest validator-top
  (testing "Validation of top element (has markup in content)"
    (let [xml {:tag :top,
               :attrs nil,
               :content
               [{:tag :h:h1,
                 :attrs {:xmlns "http://www.w3.org/1999/xhtml"},
                 :content ["Test 1"]}]}
          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml top-validations))]
      (is (= actual expected)))))

(deftest validator-foot
  (testing "Validation of foot element (has text in content)"
    (let [xml {:tag :foot,
               :attrs nil,
               :content
               [{:tag :h:p,
                 :attrs {:class "footer", :xmlns "http://www.w3.org/1999/xhtml"},
                 :content ["That's all folks!"]}]}
          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml foot-validations))]
      (is (= actual expected)))))

(deftest validator-group
  (testing "Validation of group element (has documentation)"
    (let [xml {:tag :group,
               :attrs {:name "public"},
               :content
               [{:tag :documentation, :attrs nil, :content ["All users"]}]}
          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml group-validations))]
      (is (= actual expected)))))

(deftest validator-entity
  (testing "Validation of entity element"
    (let [xml {:tag :entity,
               :attrs {:name "person"},
               :content
               [{:tag :documentation, :attrs nil, :content ["A person"]}
                {:tag :prompt,
                 :attrs {:locale "en-GB", :prompt "Person"},
                 :content nil}
                {:tag :key,
                 :attrs nil,
                 :content
                 [{:tag :property,
                   :attrs
                   {:immutable "true",
                    :required "true",
                    :distinct "system",
                    :type "integer",
                    :name "id"},
                   :content
                   [{:tag :generator, :attrs {:action "native"}, :content nil}]}]}
                {:tag :property,
                 :attrs
                 {:required "true",
                  :distinct "user",
                  :size "32",
                  :type "string",
                  :name "name"},
                 :content
                 [{:tag :prompt,
                   :attrs {:locale "en-GB", :prompt "Name"},
                   :content nil}
                  {:tag :prompt,
                   :attrs {:locale "fr-FR", :prompt "Nomme"},
                   :content nil}]}
                {:tag :property,
                 :attrs
                 {:default "Unknown", :size "8", :type "string", :name "gender"},
                 :content
                 [{:tag :option,
                   :attrs {:value "Female"},
                   :content
                   [{:tag :prompt,
                     :attrs {:locale "fr-FR", :prompt "Femme"},
                     :content nil}
                    {:tag :prompt,
                     :attrs {:locale "en-GB", :prompt "Female"},
                     :content nil}]}
                  {:tag :option,
                   :attrs {:value "Male"},
                   :content
                   [{:tag :prompt,
                     :attrs {:locale "fr-FR", :prompt "Homme"},
                     :content nil}
                    {:tag :prompt,
                     :attrs {:locale "en-GB", :prompt "Male"},
                     :content nil}]}
                  {:tag :option,
                   :attrs {:value "Non-bin"},
                   :content
                   [{:tag :prompt,
                     :attrs {:locale "fr-FR", :prompt "Non binaire"},
                     :content nil}
                    {:tag :prompt,
                     :attrs {:locale "en-GB", :prompt "Non-binary"},
                     :content nil}]}
                  {:tag :option,
                   :attrs {:value "Unknown"},
                   :content
                   [{:tag :prompt,
                     :attrs {:locale "fr-FR", :prompt "Inconnu"},
                     :content nil}
                    {:tag :prompt,
                     :attrs {:locale "en-GB", :prompt "Unknown"},
                     :content nil}]}]}
                {:tag :property,
                 :attrs {:type "integer", :name "age"},
                 :content nil}
                {:tag :property,
                 :attrs {:entity "address", :type "entity", :name "address"},
                 :content nil}
                {:tag :form,
                 :attrs {:properties "listed", :name "edit-person"},
                 :content
                 [{:tag :field, :attrs {:property "name"}, :content nil}
                  {:tag :field, :attrs {:property "gender"}, :content nil}
                  {:tag :field, :attrs {:property "age"}, :content nil}
                  {:tag :field, :attrs {:property "address"}, :content nil}
                  {:tag :permission,
                   :attrs {:permission "all", :group "admin"},
                   :content nil}
                  {:tag :permission,
                   :attrs {:permission "insert", :group "public"},
                   :content nil}]}
                {:tag :page,
                 :attrs {:properties "all", :name "inspect-person"},
                 :content nil}
                {:tag :list,
                 :attrs
                 {:on-select "edit-person",
                  :properties "all",
                  :name "list-people"},
                 :content nil}]}
          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml entity-validations))]
      (is (= actual expected)))))

(deftest validator-prompt
  (testing "Validation of prompt element"
    (let [xml {:tag :prompt,
               :attrs {:locale "en-GB", :prompt "Person"},
               :content nil}
          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml prompt-validations))]
      (is (= actual expected)))))

(deftest validator-key
  (testing "Validation of key element"
    (let [xml {:tag :key,
               :attrs nil,
               :content
               [{:tag :property,
                 :attrs
                 {:immutable "true",
                  :required "true",
                  :distinct "system",
                  :type "integer",
                  :name "id"},
                 :content
                 [{:tag :generator, :attrs {:action "native"}, :content nil}]}]}
          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml key-validations))]
      (is (= actual expected)))))

(deftest validator-property
  (testing "Validation of property element"
    (let [xml {:tag :property,
               :attrs
               {:required "true",
                :distinct "user",
                :size "32",
                :type "string",
                :name "name"},
               :content
               [{:tag :prompt,
                 :attrs {:locale "en-GB", :prompt "Name"},
                 :content nil}
                {:tag :prompt,
                 :attrs {:locale "fr-FR", :prompt "Nomme"},
                 :content nil}]}

          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml property-validations))]
      (is (= actual expected)))))

(deftest validator-property-with-options
  (testing "Validation of property element with options"
    (let [xml {:tag :property,
               :attrs
               {:default "Unknown", :size "8", :type "string", :name "gender"},
               :content
               [{:tag :option,
                 :attrs {:value "Female"},
                 :content
                 [{:tag :prompt,
                   :attrs {:locale "fr-FR", :prompt "Femme"},
                   :content nil}
                  {:tag :prompt,
                   :attrs {:locale "en-GB", :prompt "Female"},
                   :content nil}]}
                {:tag :option,
                 :attrs {:value "Male"},
                 :content
                 [{:tag :prompt,
                   :attrs {:locale "fr-FR", :prompt "Homme"},
                   :content nil}
                  {:tag :prompt,
                   :attrs {:locale "en-GB", :prompt "Male"},
                   :content nil}]}
                {:tag :option,
                 :attrs {:value "Non-bin"},
                 :content
                 [{:tag :prompt,
                   :attrs {:locale "fr-FR", :prompt "Non binaire"},
                   :content nil}
                  {:tag :prompt,
                   :attrs {:locale "en-GB", :prompt "Non-binary"},
                   :content nil}]}
                {:tag :option,
                 :attrs {:value "Unknown"},
                 :content
                 [{:tag :prompt,
                   :attrs {:locale "fr-FR", :prompt "Inconnu"},
                   :content nil}
                  {:tag :prompt,
                   :attrs {:locale "en-GB", :prompt "Unknown"},
                   :content nil}]}]}
          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml entity-validations))]
      (is (= actual expected)))))


(deftest validator-option
  (testing "Validation of option element"
    (let [xml {:tag :option,
                 :attrs {:value "Female"},
                 :content
                 [{:tag :prompt,
                   :attrs {:locale "fr-FR", :prompt "Femme"},
                   :content nil}
                  {:tag :prompt,
                   :attrs {:locale "en-GB", :prompt "Female"},
                   :content nil}]}
          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml option-validations))]
      (is (= actual expected)))))


(deftest validator-form
  (testing "Validation of form element"
    (let [xml {:tag :form,
               :attrs {:properties "listed", :name "edit-person"},
               :content
               [{:tag :field, :attrs {:property "name"}, :content nil}
                {:tag :field, :attrs {:property "gender"}, :content nil}
                {:tag :field, :attrs {:property "age"}, :content nil}
                {:tag :field, :attrs {:property "address"}, :content nil}
                {:tag :permission,
                 :attrs {:permission "all", :group "admin"},
                 :content nil}
                {:tag :permission,
                 :attrs {:permission "insert", :group "public"},
                 :content nil}]}
          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml form-validations))]
      (is (= actual expected)))))


(deftest validator-page
  (testing "Validation of page element"
    (let [xml {:tag :page,
     :attrs {:properties "all", :name "inspect-person"},
     :content nil}
          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml page-validations))]
      (is (= actual expected)))))


(deftest validator-list
  (testing "Validation of list element"
    (let [xml {:tag :list,
               :attrs
               {:on-select "edit-person",
                :properties "all",
                :name "list-people"},
               :content nil}
          expected true
          actual (binding [*out* (writer "/dev/null")]
                   (valid? xml list-validations))]
      (is (= actual expected)))))


;; (deftest validator-xxx
;;   (testing "Validation of xxx element"
;;     (let [xml
;;           expected true
;;           actual (binding [*out* (writer "/dev/null")]
;;                    (valid? xml xxx-validations))]
;;       (is (= actual expected)))))


;; (deftest validator-xxx
;;   (testing "Validation of xxx element"
;;     (let [xml
;;           expected true
;;           actual (binding [*out* (writer "/dev/null")]
;;                    (valid? xml xxx-validations))]
;;       (is (= actual expected)))))


;; (deftest validator-xxx
;;   (testing "Validation of xxx element"
;;     (let [xml
;;           expected true
;;           actual (binding [*out* (writer "/dev/null")]
;;                    (valid? xml xxx-validations))]
;;       (is (= actual expected)))))


(deftest validator-test-1
  (testing "validation of `testl.adl.xml`."
    (let [xml (parse "resources/test/test1.adl.xml")
          expected true
          actual (valid? xml application-validations)]
      (is (= actual expected)))))
