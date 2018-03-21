(ns adl.to-hugsql-queries-test
  (:require [clojure.test :refer :all]
            [adl.to-hugsql-queries :refer :all]))

(deftest entity-tests
  (let [xml {:tag :entity,
             :attrs {:name "address"},
             :content
             [{:tag :key,
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
               {:distinct "user", :size "128", :type "string", :name "street"},
               :content nil}
              {:tag :property,
               :attrs {:size "64", :type "string", :name "town"},
               :content nil}
              {:tag :property,
               :attrs
               {:distinct "user", :size "12", :type "string", :name "postcode"},
               :content nil}]}]
    (testing "user distinct properties should provide the default ordering"
      (let [expected "ORDER BY address.street,\n\taddress.postcode,\n\taddress.id"
            actual (order-by-clause xml)]
        (is (= actual expected))))
    (testing "keys name extraction"
      (let [expected '("id")
            actual (key-names xml)]
        (is (= actual expected))))
    (testing "primary key test"
      (let [expected true
            actual (has-primary-key? xml)]
        (is (= actual expected))))
    (testing "non-key properties test"
      (let [expected true
            actual (has-non-key-properties? xml)]
        (is (= actual expected))))
    (testing "insert query generation"
      (let [expected "-- :name create-addres! :! :n\n-- :doc creates a new addres record\nINSERT INTO address (street,\n\ttown,\n\tpostcode)\nVALUES (:street,\n\t:town,\n\t:postcode)\nreturning id\n\n"
            actual (:query (first (vals (insert-query xml))))]
        (is (= actual expected))))
    (testing "insert query signature"
      (let [expected ":! :n"
            actual (:signature (first (vals (insert-query xml))))]
        (is (= actual expected))))
    (testing "update query generation"
      (let [expected "-- :name update-addres! :! :n\n-- :doc updates an existing addres record\nUPDATE address\nSET street = :street,\n\ttown = :town,\n\tpostcode = :postcode\nWHERE address.id = :id\n\n"
            actual (:query (first (vals (update-query xml))))]
        (is (= actual expected))))
    (testing "update query signature"
      (let [expected ":! :n"
            actual (:signature (first (vals (update-query xml))))]
        (is (= actual expected))))
    (testing "search query generation"
      (let [expected "-- :name search-strings-addres :? :1\n-- :doc selects existing address records having any string field matching `:pattern` by substring match\nSELECT * FROM address\nWHERE street LIKE '%:pattern%'\n\tOR town LIKE '%:pattern%'\n\tOR postcode LIKE '%:pattern%'\nORDER BY address.street,\n\taddress.postcode,\n\taddress.id\n--~ (if (:offset params) \"OFFSET :offset \") \n--~ (if (:limit params) \"LIMIT :limit\" \"LIMIT 100\")\n\n"
            actual (:query (first (vals (search-query xml))))]
        (is (= actual expected))))
    (testing "search query signature"
      (let [expected ":? :1"
            actual (:signature (first (vals (search-query xml))))]
        (is (= actual expected))))
    (testing "select query generation"
      (let [expected "-- :name get-addres :? :1\n-- :doc selects an existing addres record\nSELECT * FROM address\nWHERE address.id = :id\n\n"
            actual (:query (first (vals (select-query xml))))]
        (is (= actual expected))))
    (testing "select query signature"
      (let [expected ":? :1"
            actual (:signature (first (vals (select-query xml))))]
        (is (= actual expected))))
    (testing "list query generation"
      (let [expected "-- :name list-address :? :*\n-- :doc lists all existing addres records\nSELECT * FROM address\nORDER BY address.street,\n\taddress.postcode,\n\taddress.id\n--~ (if (:offset params) \"OFFSET :offset \") \n--~ (if (:limit params) \"LIMIT :limit\" \"LIMIT 100\")\n\n"
            actual (:query (first (vals (list-query xml))))]
        (is (= actual expected))))
    (testing "list query signature"
      (let [expected ":? :*"
            actual (:signature (first (vals (list-query xml))))]
        (is (= actual expected))))
    (testing "delete query generation"
      (let [expected "-- :name delete-addres! :! :n\n-- :doc updates an existing addres record\nDELETE FROM address\nWHERE address.id = :id\n\n"
            actual (:query (first (vals (delete-query xml))))]
        (is (= actual expected))))
    (testing "delete query signature"
      (let [expected ":! :n"
            actual (:signature (first (vals (delete-query xml))))]
        (is (= actual expected))))

  ))

