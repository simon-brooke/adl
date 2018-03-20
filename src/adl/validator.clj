(ns ^{:doc "Application Description Language: validator for ADL structure."
      :author "Simon Brooke"}
  adl.validator
  (:require [clojure.set :refer [union]]
            [bouncer.core :as b]
            [bouncer.validators :as v]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; squirrel-parse.to-adl: validate Application Description Language.
;;;;
;;;; This program is free software; you can redistribute it and/or
;;;; modify it under the terms of the GNU General Public License
;;;; as published by the Free Software Foundation; either version 2
;;;; of the License, or (at your option) any later version.
;;;;
;;;; This program is distributed in the hope that it will be useful,
;;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;; GNU General Public License for more details.
;;;;
;;;; You should have received a copy of the GNU General Public License
;;;; along with this program; if not, write to the Free Software
;;;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
;;;; USA.
;;;;
;;;; Copyright (C) 2018 Simon Brooke
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defn disjunct-valid?
  ;; Yes, this is a horrible hack. I should be returning the error structure
  ;; not printing it. But I can't see how to make that work with `bouncer`.
  ;; OK, so: most of the validators will (usually) fail, and that's OK. How
  ;; do we identify the one which ought not to have failed?
  [o & validations]
  (println
   (str
    (if (:tag o) (str "Tag: " (:tag o) "; "))
    (if (:name (:attrs o)) (str "Name: " (:name (:attrs o)) ";"))
    (if-not (or (:tag o) (:name (:attrs o))) (str "Context: " o))))

  (let
    [rs (map
         #(try
            (b/validate o %)
            (catch java.lang.ClassCastException c
              ;; The validator regularly barfs on strings, which are perfectly
              ;; valid content of some elements. I need a way to validate
              ;; elements where they're not tolerated!
              [nil o])
            (catch Exception e
              [{:exception (.getMessage e)
                :class (type e)
                :context o} o]))
         validations)
     all-candidates (remove nil? (map first rs))
     suspicious (remove :tag all-candidates)]
    ;; if *any* succeeded, we succeeded
    ;; otherwise, one of these is the valid error - but which? The answer, in my case
    ;; is that if there is any which did not fail on the :tag check, then that is the
    ;; interesting one. But generally?
    (try
      (doall (map #(println (str "\tError: " %)) suspicious))
      (empty? suspicious)
      (catch Exception _ (println "Error while trying to print errors")
      true))))


;;; the remainder of this file is a fairly straight translation of the ADL 1.4 DTD into Clojure


(declare documentation-validations fieldgroup-validations )

(def permissions
  "permissions a group may have on an entity, list, page, form or field
	permissions are deemed to increase as you go right. A group cannot
	have greater permission on a field than on the form it is in, or
	greater permission on form than the entity it belongs to

	* `none`:			none
	* `read`:			select
	* `insert`:			insert
	* `noedit`:			select, insert
	* `edit`:			select, insert, update
	* `all`:			select, insert, update, delete"
  #{"none", "read", "insert", "noedit", "edit", "all"})

(def cascade-actions
  "actions which should be cascaded to dependent objects. All these values except
  'manual' are taken from Hibernate and should be passed through the adl2hibernate
  mapping transparently. Relevent only for properties with type='entity', type='link'
  and type='list'

  * `all`:       cascade delete, save and update
  * `all-delete-orphan`: see hibernate documentation; relates to transient objects only
  * `delete`:    cascade delete actions, but not save and update
  * `manual`:    cascading will be handled in manually managed code, code to
              handle cascading should not be generated
  * `save-update`: cascade save and update actions, but not delete."
  #{"all", "all-delete-orphan", "delete", "manual", "save-update"})

(def defineable-data-types
	"data types which can be used in a typedef to provide validation -
	e.g. a string can be used with a regexp or a scalar can be used with
	min and max values
	* `string`: 		varchar		java.sql.Types.VARCHAR
	* `integer`:		int			java.sql.Types.INTEGER
	* `real`:			double		java.sql.Types.DOUBLE
	* `money`:			money		java.sql.Types.INTEGER
	* `date`:			date		java.sql.Types.DATE
	* `time`:			time		java.sql.Types.TIME
	* `timestamp`:		timestamp	java.sql.Types.TIMESTAMP
	* `uploadable`:		varchar		java.sql.Types.VARCHAR
	* `image`:			varchar		java.sql.Types.VARCHAR

	uploadable is as string but points to an uploaded file; image is as
	uploadable but points to an uploadable graphical image file."
  #{"string", "integer", "real", "money", "date", "time", "timestamp", "uploadable"})

(def simple-data-types
  "data types which are fairly straightforward translations of JDBC data types
  * `boolean`:		boolean 	java.sql.Types.BIT or char(1)		  java.sql.Types.CHAR
  * `text`:			  text or		  java.sql.Types.LONGVARCHAR
  memo		    java.sql.Types.CLOB"
  (union
    defineable-data-types
    #{"boolean" "text"}))

(def complex-data-types
  "data types which are more complex than SimpleDataTypes...
	* `entity` : 		a foreign key link to another entity (i.e. the 'many' end of a
					    one-to-many link);
	* `list` :			a list of some other entity that links to me (i.e. the 'one' end of
					    a one-to-many link);
	* `link` : 			a many to many link (via a link table);
	* `defined` : 	a type defined by a typedef."
  #{"entity", "link", "list", "defined"})

(def special-data-types
  "data types which require special handling - which don't simply map onto
  common SQL data types
  * `geopos` :    a latitude/longitude pair (experimental and not yet implemented)
  * `image` :     a raster image file, in jpeg, gif, or png format (experimental, not yet implemented)
  * `message` :   an internationalised message, having different translations for different locales"
  #{"geopos", "image", "message"})

(def all-data-types (union
                     simple-data-types
                     complex-data-types
                     special-data-types))

(def content
  "content, for things like pages (i.e. forms, lists, pages)"
  #{"head", "top", "foot"})

(def field-stuff #{"field", "fieldgroup", "auxlist", "verb"})

(def page-content (union content field-stuff))

(def page-stuff (union page-content #{"permission", "pragma"}))

(def generator-actions #{"assigned", "guid", "manual", "native"})

(def sequences #{"canonical", "reverse-canonical"})

(def reference-validations
"The 'specification' and 'reference' elements are for documentation only,
	and do not contribute to the engineering of the application described.

	A reference element is a reference to a specifying document.

	* `abbr`:		The abbreviated name of the specification to which this
				reference refers
	* `section`:	The 'anchor part' (part following a hash character) which,
				when appended to the URL, will locate the exact section
				referenced.
	* `entity`:		A reference to another entity within this ADL document
	* `property`:	A reference to another property within this ADL document;
				if entity is also specified then of that entity, else of
				the ancestor entity if any"
  {:tag [v/required [#(= % :reference)]]
   [:attrs :abbr] v/string
   [:attrs :section] v/string
   [:attrs :entity] v/string ;; and should be the name of an entity within this document
   [:attrs :property] v/string ;; and should be the name of a property in that entity
   :content [[v/every documentation-validations]]})


(def specification-validations
 "The 'specification' and 'reference' elements are for documentation only,
	and do not contribute to the engineering of the application described.

	A specification element is intended chiefly to declare the reference
	documents which may be used in documentation elements later in the
	document.

	* `url`:		The URL from which the document referenced can be retrieved
	* `name`:		The full name (title) given to this document
	* `abbr`:		A convenient abbreviated name."
  {:tag [v/required [#(= % :specification)]]
   [:attrs :url] v/string
   [:attrs :name] [v/string v/required]
   [:attrs :abbr] [v/string v/required]
   :content [[v/every #(disjunct-valid?
                        documentation-validations
                        reference-validations)]]})


(def documentation-validations
  "contains documentation on the element which immediately contains it. TODO:
  should HTML markup within a documentation element be allowed? If so, are
  there restrictions?"
  {:tag [v/required [#(= % :documentation)]]
   :content [[v/every #(disjunct-valid?
                        %
                        v/string
                        reference-validations)]]
                        })

(def content-validations
  {:tag [v/required [#(= % :content)]]})

(def help-validations
	"helptext about a property of an entity, or a field of a page, form or
	list, or a typedef. Typically there will be only one of these per property
  per locale; if there are more than one all those matching the locale may
  be concatenated, or just one may be used.

	* `locale`:			the locale in which to prefer this prompt"
  {:tag [v/required [#(= % :help)]]
   [:attrs :locale] [v/string v/required [v/matches #"[a-z]{2}-[A-Z]{2}"]]})

(def ifmissing-validations
  "helpful text to be shown if a property value is missing, typically when
  a form is submitted. Typically there will be only one of these per property
  per locale; if there are more than one all those matching the locale may
  be concatenated, or just one may be used. Later there may be more sophisticated
  behaviour here.

	* `locale`:			the locale in which to prefer this prompt"
  {:tag [v/required [#(= % :if-missing)]]
   [:attrs :locale] [v/string v/required [v/matches #"[a-z]{2}-[A-Z]{2}"]]})

(def param-validations
  "A parameter passed to the generator. Again, based on the Hibernate
  implementation.

  * `name`:   the name of this parameter."
  {:tag [v/required [#(= % :param)]]
   [:attrs :name] [v/string v/required]})


(def permission-validations
  "permissions policy on an entity, a page, form, list or field

	* `group`: 			the group to which permission is granted
	* `permission`:		the permission which is granted to that group."
  {:tag [v/required [#(= % :permission)]]
   [:attrs :group] [v/string v/required] ;; TODO: and it must be the name of a group that has already been defined.
   [:attrs :permission] [v/required [v/matches permissions]]})


(def prompt-validations
	"a prompt for a property or field; used as the prompt text for a widget
	which edits it. Typically there will be only one of these per property
  per locale; if there are more than one all those matching the locale may
  be concatenated, or just one may be used.

	* `prompt`:			the prompt to use
	* `locale`:			the locale in which to prefer this prompt."
  {:tag [v/required [#(= % :prompt)]]
   [:attrs :prompt] [v/string v/required]
   [:attrs :locale] [v/string v/required [v/matches #"[a-z]{2}-[A-Z]{2}"]]})


(def option-validations
  "one of an explicit list of optional values a property may have
  NOTE: whether options get encoded at application layer or at database layer
  is UNDEFINED; either behaviour is correct. If at database layer it's also
  UNDEFINED whether they're encoded as a single reference data table or as
  separate reference data tables for each property.

  * `value`:	the value of this option."
  {:tag [v/required [#(= % :option)]]
   [:attrs :value] [v/required]
   :content [[v/every #(or
                        (b/valid? % documentation-validations)
                        (b/valid? % prompt-validations))]]})

(def pragma-validations
  "pragmatic advice to generators of lists and forms, in the form of
  name/value pairs which may contain anything. Over time some pragmas
  will become 'well known', but the whole point of having a pragma
  architecture is that it is extensible."
  {:tag [v/required [#(= % :pragma)]]
   [:attrs :name] [v/string v/required]
   [:attrs :value] [v/string v/required]})



(def generator-validations
  "marks a property which is auto-generated by some part of the system.
  This is based on the Hibernate construct, except that the Hibernate
  implementation folds both its internal generators and custom generators
  onto the same attribute. This separates them onto two attributes so we
  can police values for Hibernate's 'builtin' generators.

  * `action`:       one of the supported Hibernate builtin generators, or
                'manual'. 'native' is strongly recommended in most instances
  * `class`:        if action is 'manual', the name of a manually maintained
                class conforming to the Hibernate IdentifierGenerator
                interface, or its equivalent in other languages."
  {:tag [v/required [#(= % :generator)]]
   [:attrs :action] [v/string v/required [v/member generator-actions]]
   [:attrs :class] v/string
   :content [[v/every #(disjunct-valid? %
                         documentation-validations
                         param-validations)]]})


(def in-implementation-validations
  "information about how to translate a type into types known to different target
  languages. TODO: Once again I'm not wholly comfortable with the name; I'm not
  really comfortable that this belongs in ADL at all.

  * `target`:     the target language
  * `value`:      the type to use in that target language
  * `kind`:       OK, I confess I don't understand this, but Andrew needs it... "

  {:tag [v/required [#(= % :in-implementation)]]
   [:attrs :target] [v/string v/required]
   [:attrs :value] [v/string v/required]
   [:attrs :kind] v/string
   :content [[v/every documentation-validations]]})

(def typedef-validations
  "the definition of a defined type. At this stage a defined type is either
	* a string		in which case it must have size and pattern, or
	* a scalar		in which case it must have minimum and/or maximum
	pattern must be a regular expression as interpreted by org.apache.regexp.RE
	minimum and maximum must be of appropriate format for the datatype specified.
	Validation may be done client-side and/or server-side at application layer
	and/or server side at database layer.

  * `name`:     the name of this typedef
  * `type`:     the simple type on which this defined type is based; must be
            present unless in-implementation children are supplied
  * `size`:     the data size of this defined type
  * `pattern`:  a regular expression which values for this type must match
  * `minimum`:  the minimum value for this type (if base type is scalar)
  * `maximum`:  the maximum value for this type (if base type is scalar)"
  {:tag [v/required [#(= % :typedef)]]
   [:attrs :name] [v/required v/string]
   [:attrs :type] [[v/member defineable-data-types]]
   [:attrs :size] [[#(if
                       (string? %)
                       (integer? (read-string %))
                       (integer? %))]]
   [:attrs :pattern] v/string
   [:attrs :minimum] [[#(if
                          (string? %)
                          (integer? (read-string %))
                          (integer? %))]]
   [:attrs :maximum] [[#(if
                          (string? %)
                          (integer? (read-string %))
                          (integer? %))]]
   :content [[v/every #(or
                         (b/valid? % documentation-validations)
                         (b/valid? % in-implementation-validations)
                         (b/valid? % help-validations))]]})

(def group-validations
  "a group of people with similar permissions to one another

  * `name`: the name of this group
  * `parent`: the name of a group of which this group is subset"
  {:tag [v/required [#(= % :group)]]
   [:attrs :name] [v/string v/required]
   [:attrs :parent] v/string
   :content [[v/every documentation-validations]]})

(def property-validations
	"a property (field) of an entity (table)

	* `name`:			  the name of this property.
	* `type`:			  the type of this property.
	* `default`:		the default value of this property. There will probably be
					    magic values of this!
	* `typedef`:	  name of the typedef to use, it type = 'defined'.
	* `distinct`:		distinct='system' required that every value in the system
					    will be distinct (i.e. natural primary key);
					    distinct='user' implies that the value may be used by users
					    in distinguishing entities even if values are not formally
					    unique;
					    distinct='all' implies that the values are formally unique
					    /and/ are user friendly (NOTE: not implemented).
	* `entity`:	if type='entity', the name of the entity this property is
					    a foreign key link to.
              if type='list', the name of the entity that has a foreign
              key link to this entity
	* `farkey`:   if type='list', the name of farside key in the listed
              entity; if type='entity' and the farside field to join to
              is not the farside primary key, then the name of that
              farside field
	* `required`:		whether this propery is required (i.e. 'not null').
	* `immutable`:		if true, once a value has been set it cannot be changed.
	* `size`: 			fieldwidth of the property if specified.
	* `concrete`: if set to 'false', this property is not stored in the
              database but must be computed (manually written code must
              be provided to support this)
	* `cascade`:  what action(s) on the parent entity should be cascaded to
              entitie(s) linked on this property. Valid only if type='entity',
              type='link' or type='list'.
	* `column`:   name of the column in a SQL database table in which this property
              is stored. TODO: Think about this.
	* `unsaved-value`:
              of a property whose persistent value is set on first being
              committed to persistent store, the value which it holds before
              it has been committed"
  {:tag [v/required [#(= % :property)]]
   [:attrs :name] [v/required v/string]
   [:attrs :type] [v/required [v/member all-data-types]]
   ;; [:attrs :default] [] ;; it's allowed, but I don't have anything particular to say about it
   [:attrs :typedef] v/string
   [:attrs :distinct] [v/string [v/member #{"none", "all", "user", "system"}]]
   [:attrs :entity] v/string
   [:attrs :farkey] v/string
   [:attrs :required] [[v/member #{"true", "false"}]]
   [:attrs :immutable] [[v/member #{"true", "false"}]]
   [:attrs :size] [[#(cond
                      (empty? %) ;; it's allowed to be missing
                      true
                       (string? %)
                       (integer? (read-string %))
                      true
                       (integer? %))]]
   [:attrs :column] v/string
   [:attrs :concrete] [[v/member #{"true", "false"}]]
   [:attrs :cascade] [[v/member cascade-actions]]
   :content [[v/every #(disjunct-valid? %
                         documentation-validations
                         generator-validations
                         permission-validations
                         option-validations
                         prompt-validations
                         help-validations
                         ifmissing-validations)]]})


(def permission-validations
  "permissions policy on an entity, a page, form, list or field

  * `group`: 			the group to which permission is granted
  * `permission`:		the permission which is granted to that group"
  {:tag [v/required [#(= % :permission)]]
   [:attrs :group] [v/required v/string] ;; and it also needs to be the name of a pre-declared group
   [:attrs :permission] [[v/member permissions]]
   :content [[v/every documentation-validations]]})

(def head-validations
  "content to place in the head of the generated document; normally HTML."
  {:tag [v/required [#(= % :head)]]})

(def top-validations
  "content to place in the top of the body of the generated document;
	this is any HTML block or inline level element."
  {:tag [v/required [#(= % :top)]]})

(def foot-validations
  "content to place in the bottom of the body of the generated document;
	this is any HTML block or inline level element."
  {:tag [v/required [#(= % :foot)]]})

(def field-validations
  "a field in a form or page

  * `property`:   the property which this field displays/edits."
  {:tag [v/required [#(= % :field)]]
   [:attrs :property] [v/string v/required] ;; and it must also be the name of a property in the current entity
   :content [[v/every #(or
                         (b/valid? % documentation-validations)
                         (b/valid? % prompt-validations)
                         (b/valid? % permission-validations)
                         (b/valid? % help-validations))]]})

(def verb-validations
  "a verb is something that may be done through a form. Probably the verbs 'store'
  and 'delete' are implied, but maybe they need to be explicitly declared. The 'verb'
  attribute of the verb is what gets returned to the controller

  * `verb`  what gets returned to the controller when this verb is selected
  * `dangerous`  true if this verb causes a destructive change."
  {:tag [v/required [#(= % :verb)]]
   [:attrs :verb] [v/string v/required]
   [:attrs :dangerous] [[v/member #{"true", "false"}] v/required]})

(def order-validations
  "an ordering or records in a list
	* `property`:	the property on which to order
	* `sequence`:	the sequence in which to order"
  {:tag [v/required [#(= % :order)]]
   [:attrs :property] [v/string v/required] ;; and it must also be the name of a property in the current entity
   [:attrs :sequence] [[v/member sequences]]
   :content [[v/every documentation-validations]]})

(def auxlist-validations
  "a subsidiary list, on which entities related to primary
  entities in the enclosing page or list are listed

  * `property`:   the property of the enclosing entity that this
              list displays (obviously, must be of type='list')
  * `onselect`:   the form or page of the listed entity to call
              when an item from the list is selected
  * `canadd`:     true if the user should be able to add records
              to this list"
  {:tag [v/required [#(= % :auxlist)]]
   [:attrs :property] [v/string v/required] ;; and it must also be the name of a property of type `list` in the current entity
   [:attrs :onselect] v/string
   [:attrs :canadd] v/boolean
   :content [[v/every #(or
                         (b/valid? % documentation-validations)
                         (b/valid? % prompt-validations)
                         (b/valid? % field-validations)
                         (b/valid? % fieldgroup-validations)
                         (b/valid? % auxlist-validations)
                         (b/valid? % verb-validations))]]})

(def fieldgroup-validations
  "a group of fields and other controls within a form or list, which the
  renderer might render as a single pane in a tabbed display, for example."
  {:tag [v/required [#(= % :fieldgroup)]]
   [:attrs :name] [v/string v/required]
   :content [[v/every #(or
                         (b/valid? % documentation-validations)
                         (b/valid? % prompt-validations)
                         (b/valid? % permission-validations)
                         (b/valid? % help-validations)
                         (b/valid? % field-validations)
                         (b/valid? % fieldgroup-validations)
                         (b/valid? % auxlist-validations)
                         (b/valid? % verb-validations))]]})


(def form-validations
  "a form through which an entity may be added or edited"
  {:tag [v/required [#(= % :form)]]
   [:attrs :name] [v/required v/string]
   [:attrs :properties] [v/required [v/member #{"all", "user-distinct", "listed"}]]
   [:attrs :canadd] [[v/member #{"true", "false"}]]
   :content [[v/every #(disjunct-valid? %
                          documentation-validations
                          head-validations
                          top-validations
                          foot-validations
                          field-validations
                          fieldgroup-validations
                          auxlist-validations
                          verb-validations
                          permission-validations
                          pragma-validations)]]})

(def page-validations
  "a page on which an entity may be displayed"
  {:tag [v/required [#(= % :page)]]
   [:attrs :name] [v/required v/string]
   [:attrs :properties] [v/required [v/member #{"all", "user-distinct", "listed"}]]
   :content [[v/every #(disjunct-valid? %
                          documentation-validations
                          head-validations
                          top-validations
                          foot-validations
                          field-validations
                          fieldgroup-validations
                          auxlist-validations
                          verb-validations
                          permission-validations
                          pragma-validations)]]})

(def list-validations
  "a list on which entities of a given type are listed

	* `onselect`:		name of form/page/list to go to when
					    a selection is made from the list"
  {:tag [v/required [#(= % :list)]]
   [:attrs :name] [v/required v/string]
   [:attrs :properties] [v/required [v/member #{"all", "user-distinct", "listed"}]]
   [:attrs :onselect] v/string
   :content [[v/every #(disjunct-valid? %
                          documentation-validations
                          head-validations
                          top-validations
                          foot-validations
                          field-validations
                          fieldgroup-validations
                          auxlist-validations
                          verb-validations
                          permission-validations
                          pragma-validations
                          order-validations)]]})

(def key-validations
  {:tag [v/required [#(= % :key)]]
   :content [[v/every property-validations]]})


(def entity-validations
  "an entity which has properties and relationships; maps onto a database
	table or a Java serialisable class - or, of course, various other things

  * `name`:         obviously, the name of this entity
  * `natural-key`:  if present, the name of a property of this entity which forms
                a natural primary key [NOTE: Only partly implemented. NOTE: much of
                the present implementation assumes all primary keys will be
                integers. This needs to be fixed!] DEPRECATED: remove; replace with the
                'key' element, below.
  * `table`:        the name of the table in which this entity is stored. Defaults to same
                as name of entity. Strongly recommend this is not used unless it needs
                to be different from the name of the entity
  * `foreign`:      this entity is part of some other system; no code will be generated
                for it, although code which links to it will be generated"
  {:tag [v/required [#(= % :entity)]]
   [:attrs :name] [v/required v/string]
   [:attrs :natural-key] v/string
   [:attrs :table] v/string
   [:attrs :foreign] [[v/member #{"true", "false"}]]
   :content [[v/every #(disjunct-valid? %
                         documentation-validations
                         prompt-validations
                         content-validations
                         key-validations
                         property-validations
                         permission-validations
                         form-validations
                         page-validations
                         list-validations)]]})

(def application-validations
  {:tag [v/required [#(= % :application)]]
   [:attrs :name] [v/required v/string]
   [:attrs :version] v/string
   [:attrs :revision] v/string
   [:attrs :currency] v/string
   :content [[v/every #(disjunct-valid? %
                         specification-validations
                         documentation-validations
                         content-validations
                         typedef-validations
                         group-validations
                         entity-validations)]]})


