(ns adl.utils-test
  (:require [clojure.string :as s]
            [clojure.test :refer :all]
            [adl.utils :refer :all]))

(deftest singularise-tests
  (testing "Singularise"
    (is (= "address" (singularise "addresses")))
    (is (= "address" (singularise "address")))
    (is (= "expertise" (singularise "expertise")))))
