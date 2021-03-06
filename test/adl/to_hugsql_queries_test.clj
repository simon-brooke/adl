(ns adl.to-hugsql-queries-test
  (:require [clojure.string :as s]
            [clojure.test :refer :all]
            [adl.to-hugsql-queries :refer :all]
            [adl-support.utils :refer :all]))

(defn string-equal-ignore-whitespace?
  "I don't want unit tests to fail just because emitted whitespace changes."
  [a b]
  (if
  (and
   (string? a)
   (string? b))
   (let
     [pattern #"[\s]+"
      aa (s/replace a pattern " ")
      bb (s/replace b pattern " ")]
     (= aa bb))
    (= a b)))

(deftest order-by-tests
  (let [application {:tag :application,
             :attrs {:version "0.1.1", :name "test-app"},
             :content
             [{:tag :entity,
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
                   [{:tag :generator, :attrs {:action "native"}, :content nil}]}
                  {:tag :property,
                   :attrs
                   {:immutable "true",
                    :required "true",
                    :distinct "all",
                    :generator "assigned"
                    :type "string",
                    :size "12"
                    :name "postcode"},
                   :content
                   [{:tag :generator, :attrs {:action "native"}, :content nil}]}
                  ]}
                {:tag :property,
                 :attrs
                 {:distinct "user", :size "128", :type "string", :name "street"},
                 :content nil}
                {:tag :property,
                 :attrs {:size "64", :type "string", :name "town"},
                 :content nil}
                ]}]}
        entity (child-with-tag application :entity)]
      (testing "user distinct properties should provide the default ordering"
      (let [expected
            "ORDER BY address.street, address.postcode, address.id"
            actual (order-by-clause entity)]
        (is (string-equal-ignore-whitespace? actual expected))))))


(deftest keys-name-extraction-tests
    (let [application {:tag :application,
             :attrs {:version "0.1.1", :name "test-app"},
             :content
             [{:tag :entity,
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
                   [{:tag :generator, :attrs {:action "native"}, :content nil}]}
                  {:tag :property,
                   :attrs
                   {:immutable "true",
                    :required "true",
                    :distinct "all",
                    :generator "assigned"
                    :type "string",
                    :size "12"
                    :name "postcode"},
                   :content
                   [{:tag :generator, :attrs {:action "native"}, :content nil}]}
                  ]}
                {:tag :property,
                 :attrs
                 {:distinct "user", :size "128", :type "string", :name "street"},
                 :content nil}
                {:tag :property,
                 :attrs {:size "64", :type "string", :name "town"},
                 :content nil}
                ]}]}
        entity (child-with-tag application :entity)]
    (testing "keys name extraction"
      (let [expected #{"id" "postcode"}
            actual (key-names entity)]
        (is (= actual expected))))))


(deftest entity-tests
  (let [application {:tag :application,
             :attrs {:version "0.1.1", :name "test-app"},
             :content
             [{:tag :entity,
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
                   [{:tag :generator, :attrs {:action "native"}, :content nil}]}
                  {:tag :property,
                   :attrs
                   {:immutable "true",
                    :required "true",
                    :distinct "all",
                    :generator "assigned"
                    :type "string",
                    :size "12"
                    :name "postcode"},
                   :content
                   [{:tag :generator, :attrs {:action "native"}, :content nil}]}
                  ]}
                {:tag :property,
                 :attrs
                 {:distinct "user", :size "128", :type "string", :name "street"},
                 :content nil}
                {:tag :property,
                 :attrs {:size "64", :type "string", :name "town"},
                 :content nil}
                ]}]}
        entity (child-with-tag application :entity)]
    (testing "keys name extraction"
      (let [expected #{"id"}
            actual (key-names entity)]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "primary key test"
      (let [expected true
            actual (has-primary-key? entity)]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "non-key properties test"
      (let [expected true
            actual (has-non-key-properties? entity)]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "insert query generation"
      (let [expected "-- :name create-address! :! :n
            -- :doc creates a new address record
            INSERT INTO address (street,
              town,
              postcode)
            VALUES (':street',
              ':town',
              ':postcode')
            returning id\n\n"
            actual (:query (first (vals (insert-query entity))))]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "insert query signature"
      (let [expected ":! :n"
            actual (:signature (first (vals (insert-query entity))))]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "update query generation"
      (let [expected "-- :name update-address! :! :n
            -- :doc updates an existing address record
            UPDATE address
            SET street = :street,
              town = :town,
              postcode = :postcode
            WHERE address.id = :id\n\n"
            actual (:query (first (vals (update-query entity))))]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "update query signature"
      (let [expected ":! :n"
            actual (:signature (first (vals (update-query entity))))]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "search query generation"
      (let [expected "-- :name search-strings-addres :? :1
            -- :doc selects existing address records having any string field matching `:pattern` by substring match
            SELECT * FROM address
            WHERE street LIKE '%:pattern%'
              OR town LIKE '%:pattern%'
              OR postcode LIKE '%:pattern%'
            ORDER BY address.street,
              address.postcode,
              address.id
            --~ (if (:offset params) \"OFFSET :offset \")
            --~ (if (:limit params) \"LIMIT :limit\" \"LIMIT 100\")\n\n"
            actual (:query (first (vals (search-query entity application))))]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "search query signature"
      (let [expected ":? :1"
            actual (:signature (first (vals (search-query entity))))]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "select query generation"
      (let [expected "-- :name get-addres :? :1
            -- :doc selects an existing addres record
            SELECT * FROM address
            WHERE address.id = :id\n\n"
            actual (:query (first (vals (select-query entity))))]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "select query signature"
      (let [expected ":? :1"
            actual (:signature (first (vals (select-query entity))))]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "list query generation"
      (let [expected "-- :name list-address :? :*
            -- :doc lists all existing addres records
            SELECT * FROM address
            ORDER BY address.street,
              address.postcode,
              address.id
            --~ (if (:offset params) \"OFFSET :offset \")
            --~ (if (:limit params) \"LIMIT :limit\" \"LIMIT 100\")\n\n"
            actual (:query (first (vals (list-query entity))))]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "list query signature"
      (let [expected ":? :*"
            actual (:signature (first (vals (list-query entity))))]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "delete query generation"
      (let [expected "-- :name delete-address! :! :n
            -- :doc deletes an existing address record
            DELETE FROM address
            WHERE address.id = :id
            ANDaddress.postcode = :postcode"
            actual (:query (first (vals (delete-query entity))))]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "delete query signature"
      (let [expected ":! :n"
            actual (:signature (first (vals (delete-query entity))))]
        (is (string-equal-ignore-whitespace? actual expected))))

  ))

(deftest complex-key-tests
  (let [application {:tag :application,
             :attrs {:version "0.1.1", :name "test-app"},
             :content
             [{:tag :entity,
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
                   [{:tag :generator, :attrs {:action "native"}, :content nil}]}
                  {:tag :property,
                   :attrs
                   {:immutable "true",
                    :required "true",
                    :distinct "all",
                    :generator "assigned"
                    :type "string",
                    :size "12"
                    :name "postcode"},
                   :content
                   [{:tag :generator, :attrs {:action "native"}, :content nil}]}
                  ]}
                {:tag :property,
                 :attrs
                 {:distinct "user", :size "128", :type "string", :name "street"},
                 :content nil}
                {:tag :property,
                 :attrs {:size "64", :type "string", :name "town"},
                 :content nil}
                ]}]}
        entity (child-with-tag application :entity)]
    (testing "user distinct properties should provide the default ordering"
      (let [expected "ORDER BY address.street,
            address.postcode,
            address.id"
            actual (order-by-clause entity)]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "keys name extraction"
      (let [expected #{"id" "postcode"}
            actual (key-names entity)]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "insert query generation - compound key, non system generated field in key"
      (let [expected "-- :name create-address! :! :n
            -- :doc creates a new address record
            INSERT INTO address (street,
              town,
              postcode)
            VALUES (':street',
              ':town',
              ':postcode')
            returning
            postcode,
            id"
            actual (:query (first (vals (insert-query entity))))]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "update query generation - compound key"
      (let [expected "-- :name update-address! :! :n
            -- :doc updates an existing address record
            UPDATE address
            SET street = :street,
              town = :town
            WHERE address.id = :id
              AND address.postcode = ':postcode'\n\n"
            actual (:query (first (vals (update-query entity))))]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "search query generation - user-distinct field in key"
      (let [expected  "-- :name search-strings-address :? :*
            -- :doc selects existing address records having any string field matching the parameter of the same name by substring match
            SELECT DISTINCT * FROM lv_address\nWHERE true
            --~ (if (:street params) (str \"AND street LIKE '%\" (:street params) \"%' \"))
            --~ (if (:town params) (str \"AND town LIKE '%\" (:town params) \"%' \"))
            --~ (if (:id params) (str \"AND id = :id\"))
            --~ (if (:postcode params) (str \"AND postcode LIKE '%\" (:postcode params) \"%' \"))
            ORDER BY lv_address.street,
            lv_address.postcode,
            lv_address.id
            --~ (if (:offset params) \"OFFSET :offset \")
            --~ (if (:limit params) \"LIMIT :limit\" \"LIMIT 100\")"
            actual (:query (first (vals (search-query entity application))))]
        (is (string-equal-ignore-whitespace? actual expected))))
    (testing "delete query generation - compound key"
      (let [expected "-- :name delete-address! :! :n
            -- :doc deletes an existing address record
            DELETE FROM address\nWHERE address.id = :id
            AND address.postcode = :postcode"
            actual (:query (first (vals (delete-query entity))))]
        (is (string-equal-ignore-whitespace? actual expected))))))

;; "-- :name delete-address! :! :n\n-- :doc deletes an existing address record\nDELETE FROM address\nWHERE address.id = :id\n\tAND address.postcode = :postcode"
;; "-- :name delete-address! :! :n\n-- :doc deletes an existing address record\nDELETE FROM address\nWHERE address.id = :id\n AND address.postcode = :postcode\n\n"))
