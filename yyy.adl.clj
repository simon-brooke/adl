{:tag :application,
 :attrs {:version "0.1.1", :name "youyesyet"},
 :content
 [{:tag :entity,
   :attrs {:name "electors"},
   :content
   [{:tag :property,
     :attrs
     {:column "id", :name "id", :type "integer", :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "id"},
       :content ["\nid\n"]}]}
    {:tag :property,
     :attrs
     {:column "name", :name "name", :type "string", :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "name"},
       :content ["\nname\n"]}]}
    {:tag :property,
     :attrs
     {:farkey "id",
      :entity "addresses",
      :column "address_id",
      :name "address_id",
      :type "entity",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "address_id"},
       :content ["\naddress_id\n"]}]}
    {:tag :property,
     :attrs {:column "phone", :name "phone", :type "string"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "phone"},
       :content ["\nphone\n"]}]}
    {:tag :property,
     :attrs {:column "email", :name "email", :type "string"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "email"},
       :content ["\nemail\n"]}]}]}
  {:tag :entity,
   :attrs {:name "addresses"},
   :content
   [{:tag :property,
     :attrs
     {:column "id", :name "id", :type "integer", :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "id"},
       :content ["\nid\n"]}]}
    {:tag :property,
     :attrs
     {:column "address",
      :name "address",
      :type "string",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "address"},
       :content ["\naddress\n"]}]}
    {:tag :property,
     :attrs {:column "postcode", :name "postcode", :type "string"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "postcode"},
       :content ["\npostcode\n"]}]}
    {:tag :property,
     :attrs {:column "phone", :name "phone", :type "string"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "phone"},
       :content ["\nphone\n"]}]}
    {:tag :property,
     :attrs
     {:farkey "id",
      :entity "districts",
      :column "district_id",
      :name "district_id",
      :type "entity"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "district_id"},
       :content ["\ndistrict_id\n"]}]}
    {:tag :property,
     :attrs {:column "latitude", :name "latitude", :type "real"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "latitude"},
       :content ["\nlatitude\n"]}]}
    {:tag :property,
     :attrs {:column "longitude", :name "longitude", :type "real"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "longitude"},
       :content ["\nlongitude\n"]}]}]}
  {:tag :entity,
   :attrs {:name "visits"},
   :content
   [{:tag :property,
     :attrs
     {:column "id", :name "id", :type "integer", :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "id"},
       :content ["\nid\n"]}]}
    {:tag :property,
     :attrs
     {:farkey "id",
      :entity "addresses",
      :column "address_id",
      :name "address_id",
      :type "integer",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "address_id"},
       :content ["\naddress_id\n"]}]}
    {:tag :property,
     :attrs
     {:farkey "id",
      :entity "canvassers",
      :column "canvasser_id",
      :name "canvasser_id",
      :type "entity",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "canvasser_id"},
       :content ["\ncanvasser_id\n"]}]}
    {:tag :property,
     :attrs
     {:column "date",
      :name "date",
      :type "timestamp",
      :default "",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "date"},
       :content ["\ndate\n"]}]}]}
  {:tag :entity,
   :attrs {:name "authorities"},
   :content
   [{:tag :property,
     :attrs
     {:column "id", :name "id", :type "string", :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "id"},
       :content ["\nid\n"]}]}]}
  {:tag :entity,
   :attrs {:name "issues"},
   :content
   [{:tag :property,
     :attrs
     {:column "id", :name "id", :type "string", :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "id"},
       :content ["\nid\n"]}]}
    {:tag :property,
     :attrs {:column "url", :name "url", :type "string"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "url"},
       :content ["\nurl\n"]}]}]}
  {:tag :entity,
   :attrs {:name "schema_migrations"},
   :content
   [{:tag :property,
     :attrs
     {:column "id", :name "id", :type "integer", :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "id"},
       :content ["\nid\n"]}]}]}
  {:tag :entity,
   :attrs {:name "intentions"},
   :content
   [{:tag :property,
     :attrs
     {:column "visit_id",
      :name "visit_id",
      :farkey "id",
      :entity "visits",
      :type "entity",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "visit_id"},
       :content ["\nvisit_id\n"]}]}
    {:tag :property,
     :attrs
     {:column "elector_id",
      :name "elector_id",
      :farkey "id",
      :entity "electors",
      :type "entity",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "elector_id"},
       :content ["\nelector_id\n"]}]}
    {:tag :property,
     :attrs
     {:column "option_id",
      :name "option_id",
      :farkey "id",
      :entity "options",
      :type "entity",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "option_id"},
       :content ["\noption_id\n"]}]}]}
  {:tag :entity,
   :attrs {:name "canvassers"},
   :content
   [{:tag :property,
     :attrs {:column "id", :name "id", :type "integer"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "id"},
       :content ["\nid\n"]}]}
    {:tag :property,
     :attrs
     {:column "username",
      :name "username",
      :type "string",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "username"},
       :content ["\nusername\n"]}]}
    {:tag :property,
     :attrs
     {:column "fullname",
      :name "fullname",
      :type "string",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "fullname"},
       :content ["\nfullname\n"]}]}
    {:tag :property,
     :attrs
     {:farkey "id",
      :entity "electors",
      :column "elector_id",
      :name "elector_id",
      :type "entity"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "elector_id"},
       :content ["\nelector_id\n"]}]}
    {:tag :property,
     :attrs
     {:farkey "id",
      :entity "addresses",
      :column "address_id",
      :name "address_id",
      :type "integer",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "address_id"},
       :content ["\naddress_id\n"]}]}
    {:tag :property,
     :attrs {:column "phone", :name "phone", :type "string"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "phone"},
       :content ["\nphone\n"]}]}
    {:tag :property,
     :attrs {:column "email", :name "email", :type "string"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "email"},
       :content ["\nemail\n"]}]}
    {:tag :property,
     :attrs
     {:farkey "id",
      :entity "authorities",
      :column "authority_id",
      :name "authority_id",
      :type "string",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "authority_id"},
       :content ["\nauthority_id\n"]}]}
    {:tag :property,
     :attrs
     {:column "authorised", :name "authorised", :type "boolean"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "authorised"},
       :content ["\nauthorised\n"]}]}]}
  {:tag :entity,
   :attrs {:name "followuprequests"},
   :content
   [{:tag :property,
     :attrs
     {:column "id", :name "id", :type "integer", :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "id"},
       :content ["\nid\n"]}]}
    {:tag :property,
     :attrs
     {:farkey "id",
      :entity "electors",
      :column "elector_id",
      :name "elector_id",
      :type "integer",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "elector_id"},
       :content ["\nelector_id\n"]}]}
    {:tag :property,
     :attrs
     {:farkey "id",
      :entity "visits",
      :column "visit_id",
      :name "visit_id",
      :type "entity",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "visit_id"},
       :content ["\nvisit_id\n"]}]}
    {:tag :property,
     :attrs
     {:farkey "id",
      :entity "issues",
      :column "issue_id",
      :name "issue_id",
      :type "string",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "issue_id"},
       :content ["\nissue_id\n"]}]}
    {:tag :property,
     :attrs
     {:farkey "id",
      :entity "followupmethods",
      :column "method_id",
      :name "method_id",
      :type "string",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "method_id"},
       :content ["\nmethod_id\n"]}]}]}
  {:tag :entity,
   :attrs {:name "rolememberships"},
   :content
   [{:tag :property,
     :attrs
     {:column "role_id",
      :name "role_id",
      :farkey "id",
      :entity "roles",
      :type "entity",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "role_id"},
       :content ["\nrole_id\n"]}]}
    {:tag :property,
     :attrs
     {:column "canvasser_id",
      :name "canvasser_id",
      :farkey "id",
      :entity "canvassers",
      :type "entity",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "canvasser_id"},
       :content ["\ncanvasser_id\n"]}]}]}
  {:tag :entity,
   :attrs {:name "roles"},
   :content
   [{:tag :property,
     :attrs {:column "id", :name "id", :type "integer"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "id"},
       :content ["\nid\n"]}]}
    {:tag :property,
     :attrs
     {:column "name", :name "name", :type "string", :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "name"},
       :content ["\nname\n"]}]}]}
  {:tag :entity,
   :attrs {:name "teams"},
   :content
   [{:tag :property,
     :attrs {:column "id", :name "id", :type "integer"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "id"},
       :content ["\nid\n"]}]}
    {:tag :property,
     :attrs
     {:column "name", :name "name", :type "string", :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "name"},
       :content ["\nname\n"]}]}
    {:tag :property,
     :attrs
     {:column "district_id",
      :name "district_id",
      :farkey "id",
      :entity "districts",
      :type "entity",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "district_id"},
       :content ["\ndistrict_id\n"]}]}
    {:tag :property,
     :attrs {:column "latitude", :name "latitude", :type "real"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "latitude"},
       :content ["\nlatitude\n"]}]}
    {:tag :property,
     :attrs {:column "longitude", :name "longitude", :type "real"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "longitude"},
       :content ["\nlongitude\n"]}]}]}
  {:tag :entity,
   :attrs {:name "districts"},
   :content
   [{:tag :property,
     :attrs
     {:column "id", :name "id", :type "integer", :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "id"},
       :content ["\nid\n"]}]}
    {:tag :property,
     :attrs
     {:column "name", :name "name", :type "string", :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "name"},
       :content ["\nname\n"]}]}]}
  {:tag :entity,
   :attrs {:name "teamorganiserships"},
   :content
   [{:tag :property,
     :attrs
     {:column "team_id",
      :name "team_id",
      :farkey "id",
      :entity "teams",
      :type "entity",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "team_id"},
       :content ["\nteam_id\n"]}]}
    {:tag :property,
     :attrs
     {:column "canvasser_id",
      :name "canvasser_id",
      :farkey "id",
      :entity "canvassers",
      :type "entity",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "canvasser_id"},
       :content ["\ncanvasser_id\n"]}]}]}
  {:tag :entity,
   :attrs {:name "followupactions"},
   :content
   [{:tag :property,
     :attrs
     {:column "id", :name "id", :type "integer", :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "id"},
       :content ["\nid\n"]}]}
    {:tag :property,
     :attrs
     {:farkey "id",
      :entity "followuprequests",
      :column "request_id",
      :name "request_id",
      :type "entity",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "request_id"},
       :content ["\nrequest_id\n"]}]}
    {:tag :property,
     :attrs
     {:farkey "id",
      :entity "canvassers",
      :column "actor",
      :name "actor",
      :type "integer",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "actor"},
       :content ["\nactor\n"]}]}
    {:tag :property,
     :attrs
     {:column "date",
      :name "date",
      :type "timestamp",
      :default "",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "date"},
       :content ["\ndate\n"]}]}
    {:tag :property,
     :attrs {:column "notes", :name "notes", :type "text"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "notes"},
       :content ["\nnotes\n"]}]}
    {:tag :property,
     :attrs {:column "closed", :name "closed", :type "boolean"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "closed"},
       :content ["\nclosed\n"]}]}]}
  {:tag :entity,
   :attrs {:name "issueexpertise"},
   :content
   [{:tag :property,
     :attrs
     {:farkey "id",
      :entity "canvassers",
      :column "canvasser_id",
      :name "canvasser_id",
      :type "integer",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "canvasser_id"},
       :content ["\ncanvasser_id\n"]}]}
    {:tag :property,
     :attrs
     {:farkey "id",
      :entity "issues",
      :column "issue_id",
      :name "issue_id",
      :type "string",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "issue_id"},
       :content ["\nissue_id\n"]}]}
    {:tag :property,
     :attrs
     {:farkey "id",
      :entity "followupmethods",
      :column "method_id",
      :name "method_id",
      :type "entity",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "method_id"},
       :content ["\nmethod_id\n"]}]}]}
  {:tag :entity,
   :attrs {:name "options"},
   :content
   [{:tag :property,
     :attrs
     {:column "id", :name "id", :type "string", :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "id"},
       :content ["\nid\n"]}]}]}
  {:tag :entity,
   :attrs {:name "teammemberships"},
   :content
   [{:tag :property,
     :attrs
     {:column "team_id",
      :name "team_id",
      :farkey "id",
      :entity "teams",
      :type "entity",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "team_id"},
       :content ["\nteam_id\n"]}]}
    {:tag :property,
     :attrs
     {:column "canvasser_id",
      :name "canvasser_id",
      :farkey "id",
      :entity "canvassers",
      :type "entity",
      :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "canvasser_id"},
       :content ["\ncanvasser_id\n"]}]}]}
  {:tag :entity,
   :attrs {:name "followupmethods"},
   :content
   [{:tag :property,
     :attrs
     {:column "id", :name "id", :type "string", :required "true"},
     :content
     [{:tag :prompt,
       :attrs {:locale "en-GB", :prompt "id"},
       :content ["\nid\n"]}]}]}]}
