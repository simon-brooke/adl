              Application Description Language framework

**NOTE**: *this markdown was automatically generated from `adl_user_doc.html`, which in turn was taken from the Wiki page on which this documentation was originally written.*

Application Description Language framework
==========================================

## Contents
--------

*   [1 What is Application Description Language?](#What_is_Application_Description_Language.3F)
*   [2 Current versions](#Current_versions)
*   [3 What is the Application Description Language Framework?](#What_is_the_Application_Description_Language_Framework.3F)
*   [4 Why does it matter?](#Why_does_it_matter.3F)
    *   [4.1 Automated Application Generation](#Automated_Application_Generation)
    *   [4.2 Integration with hand-written code](#Integration_with_hand-written_code)
    *   [4.3 High quality auto-generated code](#High_quality_auto-generated_code)
*   [5 What can the Application Description Language framework now do?](#What_can_the_Application_Description_Language_framework_now_do.3F)
    *   [5.1 adl2entityclass.xsl](#adl2entityclass.xsl)
    *   [5.2 adl2mssql.xsl](#adl2mssql.xsl)
    *   [5.3 adl2views.xsl](#adl2views.xsl)
    *   [5.4 adl2controllerclasses.xsl](#adl2controllerclasses.xsl)
    *   [5.5 adl2hibernate.xsl](#adl2hibernate.xsl)
    *   [5.6 adl2pgsql.xsl](#adl2pgsql.xsl)
*   [6 So is ADL a quick way to build Monorail applications?](#So_is_ADL_a_quick_way_to_build_Monorail_applications.3F)
*   [7 Limitations on ADL](#Limitations_on_ADL)
    *   [7.1 Current limitations](#Current_limitations)
        *   [7.1.1 Authentication model](#Authentication_model)
        *   [7.1.2 Alternative Verbs](#Alternative_Verbs)
    *   [7.2 Inherent limitations](#Inherent_limitations)
*   [8 ADL Vocabulary](#ADL_Vocabulary)
    *   [8.1 Basic definitions](#Basic_definitions)
        *   [8.1.1 Permissions](#Permissions)
        *   [8.1.2 Data types](#Data_types)
        *   [8.1.3 Definable data types](#Definable_data_types)
        *   [8.1.4 Page content](#Page_content)
    *   [8.2 The Elements](#The_Elements)
        *   [8.2.1 Application](#Application)
        *   [8.2.2 Definition](#Definition)
        *   [8.2.3 Groups](#Groups)
        *   [8.2.4 Enities and Properties](#Enities_and_Properties)
        *   [8.2.5 Options](#Options)
        *   [8.2.6 Permissions](#Permissions_2)
        *   [8.2.7 Pragmas](#Pragmas)
        *   [8.2.8 Prompts, helptexts and error texts](#Prompts.2C_helptexts_and_error_texts)
        *   [8.2.9 Forms, Pages and Lists](#Forms.2C_Pages_and_Lists)
*   [9 Using ADL in your project](#Using_ADL_in_your_project)
    *   [9.1 Selecting the version](#Selecting_the_version)
    *   [9.2 Integrating into your build](#Integrating_into_your_build)
        *   [9.2.1 Properties](#Properties)
        *   [9.2.2 Canonicalisation](#Canonicalisation)
        *   [9.2.3 Generate NHibernate mapping](#Generate_NHibernate_mapping)
        *   [9.2.4 Generate SQL](#Generate_SQL)
        *   [9.2.5 Generate C# entity classes ('POCOs')](#Generate_C.23_entity_classes_.28.27POCOs.27.29)
        *   [9.2.6 Generate Monorail controller classes](#Generate_Monorail_controller_classes)
        *   [9.2.7 Generate Velocity views for use with Monorail](#Generate_Velocity_views_for_use_with_Monorail)

## What is Application Description Language?
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Application Description Language is an XML vocabulary, defined in a [Document Type Definition](http://en.wikipedia.org/wiki/Document_Type_Definition "http://en.wikipedia.org/wiki/Document_Type_Definition"), which declaratively describes the entities in an application domain, their relationships, and their properties. Because ADL is defined in a formal definition which can be parsed by XML editors, any DTD-aware XML editor (such as that built into Visual studio) can provide context-sensitive auto-completion for ADL, making the vocabulary easy to learn and to edit. It would perhaps be desirable to replace this DTD at some future stage with an XML Schema, since it is desirable to be able to mix HTML in with ADL in the same document.

ADL is thus a '[Fourth Generation Language](http://en.wikipedia.org/wiki/Fourth-generation_programming_language "http://en.wikipedia.org/wiki/Fourth-generation_programming_language")' as understood in the 1980s - an ultra-high level language for a specific problem domain; but it is a purely declarative 4GL.

## Current versions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------

*   The current STABLE version of ADL is 1.1.
    *   The namespace URL for ADL 1.1 is [http://libs.cygnets.co.uk/adl/1.1/](http://libs.cygnets.co.uk/adl/1.1/ "http://libs.cygnets.co.uk/adl/1.1/")
    *   Transforms for ADL 1.1 can be found at [http://libs.cygnets.co.uk/adl/1.1/ADL/transforms/](http://libs.cygnets.co.uk/adl/1.1/ADL/transforms/ "http://libs.cygnets.co.uk/adl/1.1/ADL/transforms/")
    *   The document type definition for ADL 1.1 can be found at [http://libs.cygnets.co.uk/adl/1.1/ADL/schemas/adl-1.1.dtd](http://libs.cygnets.co.uk/adl/1.1/ADL/schemas/adl-1.1.dtd "http://libs.cygnets.co.uk/adl/1.1/ADL/schemas/adl-1.1.dtd")
*   the current UNSTABLE version of ADL is 1.2. The namespace URL for ADL 1.2 is [http://libs.cygnets.co.uk/adl/1.2/](http://libs.cygnets.co.uk/adl/1.2/ "http://libs.cygnets.co.uk/adl/1.2/")
    *   The namespace URL for ADL 1.2 is [http://libs.cygnets.co.uk/adl/1.2/](http://libs.cygnets.co.uk/adl/1.2/ "http://libs.cygnets.co.uk/adl/1.2/")
    *   Transforms for ADL 1.2 can be found at [http://libs.cygnets.co.uk/adl/1.2/ADL/transforms/](http://libs.cygnets.co.uk/adl/1.2/ADL/transforms/ "http://libs.cygnets.co.uk/adl/1.2/ADL/transforms/")
    *   The document type definition for ADL 1.2 can be found at [http://libs.cygnets.co.uk/adl/1.2/ADL/schemas/adl-1.2.dtd](http://libs.cygnets.co.uk/adl/1.2/ADL/schemas/adl-1.2.dtd "http://libs.cygnets.co.uk/adl/1.2/ADL/schemas/adl-1.2.dtd")

\ What is the Application Description Language Framework?
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

The Application Description Language Framework is principally a set of XSL transforms which transform a single ADL file into all the various source files required to build an application.

## Why does it matter?
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

The average data driven web application comprises pages (lists) which show lists of entities, pages (forms) that edit instances of entities, and pages (inspectors) that show details of instances of entities. That comprises 100% of many applications and 90% of others; traditionally, even with modern tools like Monorail, coding these lists, forms and inspectors has taken 90% of the development effort.

I realised about three years ago that I was doing essentially the same job over and over again, and I don't like doing that. I see my mission in life as being to automate people out of jobs, and that includes me. So the object of the Application Description Language is to raise the level of abstraction with which we define data driven applications one level higher, and automate the process we have thus far done as programmers. This isn't a new insight; it's fundamentally the same insight that led machine code programmers to develop the first macro assembler, and led assembly language programmers to write the first high level language compiler. Computers are tools which can be used to mung information from one representation to another, and all we need to do is to work out how to write a powerful enough representation, and how to transform it.

The whole purpose of ADL is to increase productivity - mine, and that of anyone else who chooses to follow me down this path. It is pragmatic technology - it is designed to be an 80/20 or 90/10 solution, taking the repetitious grunt-work out of application development so that we can devote more time to the fun, interesting and novel bits. It is not intended to be an academic, perfect, 100% solution - although for many applications it may in practice be a 100% solution.

###  Automated Application Generation

Thus to create a new application, all that should be necessary is to create a new ADL file, and to compile it using a single, standardised \[[NAnt](http://nant.sourceforge.net/ "http://nant.sourceforge.net/")\] (or \[[Ant](http://ant.apache.org/ "http://ant.apache.org/")\]) build file using scripts already created as part of the framework. All these scripts (with the exception of the PSQL one, which was pre-existing) have been created as part of the [C1873 - SRU - Hospitality](http://wiki.cygnets.co.uk/index.php/C1873_-_SRU_-_Hospitality "C1873 - SRU - Hospitality") contract, but they contain almost no SRU specific material (and what does exist has been designed to be factored out). Prototype 1 of the SRU Hospitality Application contains no hand-written code whatever - all the application code is automatically generated from the single ADL file. The one exception to this rule is the CSS stylesheet which provides look-and-feel and branding.

###  Integration with hand-written code

Application-specific procedural code, covering specific business procedures, may still need to be hand written; the code generated by the ADL framework is specifically designed to make it easy to integrate hand-written code. Thus for example the C# entity controller classes generated are intentionally generated as _partial_ classes, so that they may be complemented by other partial classes which may be manually maintained and held in a version control system.

###  High quality auto-generated code

One key objective of the framework is that the code which is generated should be as clear and readable - and as well commented - as the best hand-written code. Consider this example:

      /// <summary>
      /// Store the record represented by the parameters passed in an HTTP service
      /// Without Id -> it's new, I create a new persistent object;
      /// With Id -> it's existing, I update the existing persistent object
      /// </summary>
      \[AccessibleThrough( Verb.Post)\]
      public void Store()
      {
        ISession hibernator =
          NHibernateHelper.GetCurrentSession( Session\[ NHibernateHelper.USERTOKEN\],
                                              Session\[NHibernateHelper.PASSTOKEN\]);

        SRU.Hospitality.Entities.Event record;


        if ( Params\[ "instance.Date" \] == null)
        {
          AddError( "You must supply a value for Date");
        }


        if ( Params\[ "instance.Description" \] == null)
        {
          AddError( "You must supply a value for Description");
        }



        string id = Params\["instance.EventId"\];

        if ( String.IsNullOrEmpty( id))
        {
          /\* it's new, create persistent object */
          record = new SRU.Hospitality.Entities.Event();

          /\* perform any domain knowledge behaviour on the new record
           \* after instantiation */
          record.AfterCreationHook();
        }
        else
        {
          /\* it's existing, retrieve it */
          record =
            hibernator.CreateCriteria(typeof(Event))
              .Add(Expression.Eq("EventId", Int32.Parse(id)))
              .UniqueResult<SRU.Hospitality.Entities.Event>();
        }

        if ( record != null)
        {
          /\* perform any domain knowledge behaviour on the record prior to updating */
          record.BeforeUpdateHook();

          /\* actually update the record */
          BindObjectInstance( record, ParamStore.Form, "instance");



          /\* write the record to the database, in order to guarantee we have a valid key */
          hibernator.Save(record);
          hibernator.Flush();

          /\* perform any domain knowledge behaviour on the record after updating */
          record.AfterUpdateHook();

          PropertyBag\["username"\] = Session\[ NHibernateHelper.USERTOKEN\];
          PropertyBag\["instance"\] = record;


          RenderViewWithFailover("edit.vm", "edit.auto.vm");
        }
        else
        {
          throw new Exception( String.Format( "No record of type Event with key value {0} found", id));
        }
      }

This means that it should be trivial to decide at some point in development of a project to manually modify and maintain auto-generated code.

## What can the Application Description Language framework now do?
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Currently the framework includes:

###  adl2entityclass.xsl

Transforms the ADL file into C# source files for classes which describe the entities in a manner acceptable to [NHibernate](http://www.hibernate.org/ "http://www.hibernate.org/"), a widely used Object/Relational mapping layer.

###  adl2mssql.xsl

Transforms the ADL file into an SQL script in Microsoft SQL Server 2000 syntax which initialises the database required by the application, with all relationships, permissions, referential integrity constraints and so on.

###  adl2views.xsl

Transforms the ADL file into [Velocity](http://velocity.apache.org/ "http://velocity.apache.org/") template files as used by the [Monorail](http://www.castleproject.org/monorail/index.html "http://www.castleproject.org/monorail/index.html") framework, one template each for all the lists, forms and inspectors described in the ADL.

###  adl2controllerclasses.xsl

Transforms the ADL file into a series of C# source files for classes which are controllers as used by the Monorail framework.

###  adl2hibernate.xsl

Transforms the ADL file into a Hibernate mapping file, used by the [Hibernate](http://www.hibernate.org/ "http://www.hibernate.org/") ([Java](http://java.sun.com/ "http://java.sun.com")) and [NHibernate](http://www.hibernate.org/ "http://www.hibernate.org/") (C#) Object/Relational mapping layers. This transform is relatively trivial, since ADL is not greatly different from being a superset of the Hibernate vocabulary - it describes the same sorts of things but in more detail.

###  adl2pgsql.xsl

Transforms the ADL file into an SQL script in [Postgres](http://www.postgresql.org/ "http://www.postgresql.org/") 7 syntax which initialises the database required by the application, with all relationships, permissions, referential integrity constraints and so on.

## So is ADL a quick way to build Monorail applications?
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Yes and no.

ADL _is_ a quick way to build Monorail applications, because it seemed to me that as Monorail/NHibernate are technologies that the company is adopting and it would be better to work with technologies with which we already have expertise - it's no good doing these things if other people can't maintain them afterwards.

However ADL wasn't originally conceived with Monorail in mind. It was originally intended to generated LISP for [CLHTTPD](http://www.cl-http.org:8001/cl-http/ "http://www.cl-http.org:8001/cl-http/"), and I have a half-finished set of scripts to generate Java as part of the Jacquard2 project which I never finished. Because ADL is at a level of abstraction considerably above any [3GL](http://en.wikipedia.org/wiki/Third-generation_programming_language "http://en.wikipedia.org/wiki/Third-generation_programming_language"), it is inherently agnostic to what 3GL it is compiled down to - so that it would be as easy to write transforms that compiled ADL to [Struts](http://struts.apache.org/ "http://struts.apache.org/") or [Ruby on Rails](http://www.rubyonrails.org/ "http://www.rubyonrails.org/") as to C#/Monorail. More importantly, ADL isn't inherently limited to Web applications - it doesn't actually know anything about the Web. It should be possible to write transforms which compile ADL down to Windows native applications or to native applications for mobile phones (and, indeed, if we did have those transforms then we could make all our applications platform agnostic).

## Limitations on ADL
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###  Current limitations

Although I've built experimental systems before using ADL, the SRU project is the first time I've really used it in anger. There are some features I need which it can't yet represent.

####  Authentication model

For SRU, I have implemented an authentication model which authenticates the user against real database user accounts. I've done this because I think, in general, this is the correct solution, and because without this sort of authentication you cannot implement table-layer security. However most web applications use application layer authentication rather than database layer authentication, and I have not yet written controller-layer code to deal with this. So unless you do so, ADL applications can currently only authenticate at database layer.

ADL defines field-level permissions, but the current controller generator does not implement this.

####  Alternative Verbs

Generically, with an entity form, one needs to be able to save the record being edited, and one (often) needs to be able to delete it. But sometimes one needs to be able to do other things. With SRU, for example, there is a need to be able to export event data to [Perfect Table Plan](http://www.perfecttableplan.com/ "http://www.perfecttableplan.com/"), and to reimport data from Perfect Table Plan. This will need custom buttons on the event entity form, and will also need hand-written code at the controller layer to respond to those buttons.

Also, a person will have, over the course of their interaction with the SRU, potentially many invitations. In order to access those invitations it will be necessary to associate lists of dependent records with forms. Currently ADL cannot represent these.

###  Inherent limitations

At this stage I doubt whether there is much point in extending ADL to include a vocabulary to describe business processes. It would make the language much more complicated, and would be unlikely to be able to offer a significantly higher level of abstraction than current 3GLs. If using ADL does not save work, it isn't worth doing it in ADL; remember this is conceived as an 80/20 solution, and you need to be prepared to write the 20 in something else.

## ADL Vocabulary
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

This section of this document presents and comments on the existing ADL document type definition (DTD).

###  Basic definitions

The DTD starts with some basic definitions

<!\-\-  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::  \-\->
<!\-\-  Before we start: some useful definitions                                       -->
<!\-\-  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::  \-\->

<!\-\- boolean means true or false -->
<!ENTITY % Boolean "(true|false)" >

<!\-\-
        Locale is a string comprising an ISO 639 language code followed by a space
        followed by an ISO 3166 country code, or else the string 'default'. See:
        <URL:http://www.ics.uci.edu/pub/ietf/http/related/iso639.txt>
        <URL:http://www.chemie.fu-berlin.de/diverse/doc/ISO_3166.html>
-->
<!ENTITY % Locale "CDATA" >

####  Permissions

Key to any data driven application is who has authority to do what to what: 'permissions'.

<!\-\-
        permissions a group may have on an entity, list, page, form or field
        permissions are deemed to increase as you go right. A group cannot
        have greater permission on a field than on the form it is in, or
        greater permission on form than the entity it belongs to

        none:                   none
        read:                   select
        insert:                 insert
        noedit:                 select, insert
        edit:                   select, insert, update
        all:                    select, insert, update, delete
-->
<!ENTITY % Permissions "none|read|insert|noedit|edit|all" >

####  Data types

ADL needs to know what type of data can be stored on different properties of different entities. The data types were originally based on JDBC data types:

<!\-\-
        data types which can be used in a definition to provide validation -
        e.g. a string can be used with a regexp or a scalar can be used with
        min and max values
        string:                 varchar         java.sql.Types.VARCHAR
        integer:                int             java.sql.Types.INTEGER
        real:                   double          java.sql.Types.DOUBLE
        money:                  money           java.sql.Types.INTEGER
        date:                   date            java.sql.Types.DATE
        time:                   time            java.sql.Types.TIME
        timestamp:              timestamp       java.sql.Types.TIMESTAMP
-->

####  Definable data types

However, in order to be able to do data validation, it's useful to associate rules with data types. ADL has the concept of definable data types, to allow data validation code to be generated from the declarative description. These definable data types are used in the ADL application, for example, to define derived types for phone numbers, email addresses, postcodes, and range types.

<!ENTITY % DefinableDataTypes "string|integer|real|money|date|time|timestamp" >

<!\-\-
        data types which are fairly straightforward translations of JDBC data types
        boolean:                boolean or      java.sql.Types.BIT
                                char(1)         java.sql.Types.CHAR
        text:                   text or         java.sql.Types.LONGVARCHAR
                                memo            java.sql.Types.CLOB
-->
<!ENTITY % SimpleDataTypes "%DefinableDataTypes;|boolean|text" >

<!\-\-
        data types which are more complex than SimpleDataTypes...
        entity :           a foreign key link to another entity;
        link :                     a many to many link (via a link table);
        defined :          a type defined by a definition.
-->
<!ENTITY % ComplexDataTypes "entity|link|defined" >

<!\-\- all data types -->
<!ENTITY % AllDataTypes "%ComplexDataTypes;|%SimpleDataTypes;" >

####  Page content

Pages in applications typically have common, often largely static, sections above, below, to the left or right of the main content which incorporates things like branding, navigation, and so on. This can be defined globally or per page. The intention is that the `head`, `top` and `foot` elements in ADL should be allowed to contain arbitrary HTML, but currently I don't have enough skill with DTD design to know how to specify this.

<!\-\- content, for things like pages (i.e. forms, lists, pages) -->
<!ENTITY % Content "head|top|foot" >

<!ENTITY % PageContent "%Content;|field" >

<!ENTITY % PageStuff "%PageContent;|permission|pragma" >

<!ENTITY % PageAttrs
        "name CDATA #REQUIRED
         properties (all|listed) #REQUIRED" >

###  The Elements

####  Application

The top level element of an Application Description Language file is the application element:

<!\-\- the application that the document describes: required top level element -->
<!ELEMENT application ( content?, definition*,  group*, entity*)>
<!ATTLIST application
        name            CDATA                                           #REQUIRED
        version         CDATA                                           #IMPLIED>

####  Definition

In order to be able to use defined types, you need to be able to provide definitions of these types:

<!\-\-
        the definition of a defined type. At this stage a defined type is either
        a string                in which case it must have size and pattern, or
        a scalar                in which case it must have minimum and/or maximum
        pattern must be a regular expression as interpreted by org.apache.regexp.RE
        minimum and maximum must be of appropriate format for the datatype specified.
        Validation may be done client-side and/or server-side at application layer
        and/or server side at database layer.
-->
<!ELEMENT definition (help*) >
<!ATTLIST definition
        name            CDATA                                           #REQUIRED
        type            (%DefinableDataTypes;)          #REQUIRED
        size            CDATA                                           #IMPLIED
        pattern         CDATA                                           #IMPLIED
        minimum         CDATA                                           #IMPLIED
        maximum         CDATA                                           #IMPLIED>

####  Groups

In order to be able to user permissions, we need to define who has those permissions. Groups in ADL map directly onto groups/roles at SQL level, but the intention with ADL is that groups should be defined hierarchically.

<!\-\- a group of people with similar permissions to one another -->
<!ELEMENT group EMPTY>
<!\-\- the name of this group -->
<!ATTLIST group name CDATA #REQUIRED>
<!\-\- the name of a group of which this group is subset -->
<!ATTLIST group parent CDATA #IMPLIED>

####  Enities and Properties

A thing-in-the-domain has properties. Things in the domain fall into regularities, groups of things which share similar collections of properties, such that the values of these properties may have are constrained. This is a representation of the world which is not perfect, but which is sufficiently useful to be recognised by the software technologies which ADL abstracts, so we need to be able to define these. Hence we have entities and properties/

<!\-\-
        an entity which has properties and relationships; maps onto a database
        table or a Java serialisable class - or, of course, various other things
-->
<!ELEMENT entity ( content?, property*, permission*, (form | page | list)*)>
<!ATTLIST entity name CDATA #REQUIRED>

<!\-\-
        a property (field) of an entity (table)

        name:                   the name of this property.
        type:                   the type of this property.

        default:                the default value of this property. There will probably be
                                        magic values of this!
        definition:             name of the definition to use, it type = 'defined'.
        distinct:               distinct='system' required that every value in the system
                                        will be distinct (i.e. natural primary key);
                                        distinct='user' implies that the value may be used by users
                                        in distinguishing entities even if values are not formally
                                        unique;
                                        distinct='all' implies that the values are formally unique
                                        /and/ are user friendly.
        entity:                 if type='entity', the name of the entity this property is
                                        a foreign key link to.
        required:               whether this propery is required (i.e. 'not null').
        size:                   fieldwidth of the property if specified.
-->
<!ELEMENT property ( option*, prompt*, help*, ifmissing*)>

<!ATTLIST property
        name            CDATA                                           #REQUIRED
        type            (%AllDataTypes;)                                #REQUIRED
        default         CDATA                                           #IMPLIED
        definition      CDATA                                           #IMPLIED
        distinct        (none|all|user|system)                          #IMPLIED
        entity          CDATA                                           #IMPLIED
        required        %Boolean;                                       #IMPLIED
        size            CDATA                                           #IMPLIED>

####  Options

Sometimes a property has a constrained list of specific values; this is represented for example in the enumerated types supported by many programming languages. Again, we need to be able to represent this.

<!\-\-
        one of an explicit list of optional values a property may have
        NOTE: whether options get encoded at application layer or at database layer
        is UNDEFINED; either behaviour is correct. If at database layer it's also
        UNDEFINED whether they're encoded as a single reference data table or as
        separate reference data tables for each property.
-->
<!ELEMENT option (prompt*)>
<!\-\- if the value is different from the prompt the user sees, specify it -->
<!ATTLIST option value CDATA #IMPLIED>

####  Permissions

Permissions define policies to allow groups of users to access forms, pages, fields (not yet implemented) or entities. Only entity permissions are enforced at database layer, and field protection is not yet implemented at controller layer. But the ADL allows it to be described, and future implementations of the controller generating transform will do this.

<!\-\-
        permissions policy on an entity, a page, form, list or field

        group:                  the group to which permission is granted
        permission:             the permission which is granted to that group
-->
<!ELEMENT permission EMPTY>
<!ATTLIST permission
        group           CDATA                                   #REQUIRED
        permission      (%Permissions;)                         #REQUIRED>

####  Pragmas

Pragmas are currently not used at all. They are there as a possible means to provide additional controls on forms, but may not be the correct solutions for that.

<!--
  pragmatic advice to generators of lists and forms, in the form of
  name/value pairs which may contain anything. Over time some pragmas
  will become 'well known', but the whole point of having a pragma
  architecture is that it is extensible.
-->
<!ELEMENT pragma EMPTY>
<!ATTLIST pragma
      name  CDATA   #REQUIRED
      value CDATA   #REQUIRED>

####  Prompts, helptexts and error texts

When soliciting a value for a property from the user, we need to be able to offer the user a prompt to describe what we're asking for, and we need to be able to offer that in the user's preferred natural language. Prompts are typically brief. Sometimes, however, we need to give the user a more extensive description of what is being solicited - 'help text'. Finally, if the data offered by the user isn't adequate for some reason, we need ways of feeding that back. Currently the only error text which is carried in the ADL is 'ifmissing', text to be shown if the value for a required property is missing. All prompts, helptexts and error texts have locale information, so that it should be possible to generate variants of all pages for different natural languages from the same ADL.

<!\-\-
  a prompt for a property or field; used as the prompt text for a widget
  which edits it. Typically there will be only one of these per property
  per locale; if there are more than one all those matching the locale may
  be concatenated, or just one may be used.

        prompt:                 the prompt to use

        locale:                 the locale in which to prefer this prompt
-->
<!ELEMENT prompt EMPTY>
<!ATTLIST prompt
        prompt          CDATA                                           #REQUIRED
        locale          %Locale;                                        #IMPLIED >

<!\-\-
  helptext about a property of an entity, or a field of a page, form or
  list, or a definition. Typically there will be only one of these per property
  per locale; if there are more than one all those matching the locale may
  be concatenated, or just one may be used.

        locale:                 the locale in which to prefer this prompt
-->
<!ELEMENT help (#PCDATA)>
<!ATTLIST help
        locale          %Locale;                                        #IMPLIED >

<!--
  helpful text to be shown if a property value is missing, typically when
  a form is submitted. Typically there will be only one of these per property
  per locale; if there are more than one all those matching the locale may
  be concatenated, or just one may be used. Later there may be more sophisticated
  behaviour here.
-->
<!ELEMENT ifmissing (#PCDATA)>
<!ATTLIST ifmissing
      locale  %Locale;  #IMPLIED>

####  Forms, Pages and Lists

The basic pages of the user interface. Pages and Forms by default show fields for all the properties of the entity they describe, or they may show only a listed subset. Currently lists show fields for only those properties which are 'user distinct'. Forms, pages and lists may each have their own head, top and foot content, or they may inherit the content defined for the application.

<!\-\- a form through which an entity may be added or edited -->
<!ELEMENT form ( %PageStuff;)*>
<!ATTLIST form %PageAttrs;>


<!\-\- a page on which an entity may be displayed -->
<!ELEMENT page ( %PageStuff;)*>
<!ATTLIST page %PageAttrs;>


<!\-\-
        a list on which entities of a given type are listed

        onselect:               name of form/page/list to go to when
                                a selection is made from the list
-->
<!ELEMENT list ( %PageStuff;)*>
<!ATTLIST list %PageAttrs;
        onselect        CDATA                                           #IMPLIED >


<!\-\- a field in a form or page -->
<!ELEMENT field (prompt*, help*, permission*) >
<!ATTLIST field property CDATA #REQUIRED >


<!\-\- a container for global content -->
<!ELEMENT content (%Content;)*>


<!\-\-
        content to place in the head of the generated document; this is #PCDATA
        because it will almost certainly belong to a different namespace
        (usually HTML)
-->
<!ELEMENT head (#PCDATA) >


<!\-\-
        content to place in the top of the body of the generated document;
        this is #PCDATA because it will almost certainly belong to a different
        namespace (usually HTML)
-->
<!ELEMENT top (#PCDATA) >


<!\-\-
        content to place at the foot of the body of the generated document;
        this is #PCDATA because it will almost certainly belong to a different
        namespace (usually HTML)
-->
<!ELEMENT foot (#PCDATA) >

## Using ADL in your project
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###  Selecting the version

Current versions of ADL are given at the top of this document. Historical versions are as follows:

*   **Version 0.1**: Used by the SRU Hospitality application only. The Hospitality Application will be upgraded to the current version whenever it has further work done on it.
    *   You cannot access Version 1.0 at all, as nothing in current development should be using it. It is in CVS as part of the SRU Hospitality application
    *   As soon as SRU Hospitality has been updated to **stable**, version 0.1 will be unmaintained.
*   **Version 0.3**: Identical to Version 1.0, except that the obsolete _transforms01_ directory has not been removed.
    *   You can access 0.3, should you need to, here: [http://libs.cygnets.co.uk/adl/0.3/ADL/](http://libs.cygnets.co.uk/adl/0.3/ADL/ "http://libs.cygnets.co.uk/adl/0.3/ADL/")
    *   I do not plan to maintain 0.3 even for bugfixes; you should ensure your project builds with 1.0
*   **Version 1.0**: Identical to Version 3.0, except tidied up.
    *   *   the obsolete _transforms01_ directory has been removed.
        *   _adl2entityclass.xslt_ has been renamed to _adl2entityclasses.xslt_, for consistency
    *   This is the current **stable** branch; it is the HEAD branch in CVS.
    *   If there are bugs, I (sb) will fix them.
    *   If you want new functionality, it belongs in 'unstable'.
    *   You can access 1.0 here: [http://libs.cygnets.co.uk/adl/1.0/ADL/](http://libs.cygnets.co.uk/adl/1.0/ADL/ "http://libs.cygnets.co.uk/adl/1.0/ADL/")
    *   Projects using ADL 1.0 should be built with the 1.0 version of CygnetToolkit
*   **unstable**: this is the current development branch, the branch tagged **b_development** in CVS.
    *   It should be backwards compatible with 1.0 (i.e. anything which builds satisfactorily with 1.0 should also build with unstable)
    *   It may have additional features
    *   It is not guaranteed to work, and before a final release of a product to a customer we may wish to move changes into a new 'stable' branch.
    *   You can access the unstable branch here: [http://libs.cygnets.co.uk/adl/unstable/ADL/](http://libs.cygnets.co.uk/adl/unstable/ADL/ "http://libs.cygnets.co.uk/adl/unstable/ADL/")
    *   The version at that location is automatically updated from CVS every night
    *   Projects using the **b_development** branch of ADL should be built against the **b_development** branch of CygnetToolkit.

###  Integrating into your build

To use ADL, it is currently most convenient to use NAnt. It is probably possible to do this with MSBuild, but as of yet I don't know how.

####  Properties

For the examples given here to work, you will need to set up at least the following properties in your NAnt `.build` file:

   <property name="project.name" value="YourProjectName"/>
        <property name="src.dir" value="YourSourceDir"/>
        <property name="tmpdir" value="tmp"/>
        <property name="assembly" value="${project.name}"/>
        <property name="adl" value="L:/adl/unstable/ADL/"/>
        <property name="adl-transforms" value="${adl}/transforms"/>
        <property name="adl-src" value="${src.dir}/${project.name}.adl.xml"/>
        <property name="canonical" value="${tmpdir}/Canonical.adl.xml"/>
        <property name="nant-tasks" value="${tmpdir}/NantTasks.dll"/>
        <property name="nsroot" value="Uk.Co.Cygnets"/>
        <property name="entityns" value="${nsroot}.${assembly}.Entities"/>
        <property name="controllerns" value="${nsroot}.${assembly}.Controllers"/>
        <property name="entities" value="${src-dir}/Entities"/>
        <property name="controllers" value="${src-dir}/Controllers"/>

where, obviously, **YourProjectName**, **YourSourceDir** and **YourADL.adl.xml** stand in for the actual names of your project, your source directory (relative to your solution directory, where the .build file is) and your ADL file, respectively. Note that if it is to be used as an assembly name, the project name should include neither spaces, hyphens nor periods. If it must do so, you should give an assembly name which does not, explicitly.

####  Canonicalisation

The first thing you need to do with your ADL file is canonicalise it. You should generally not need to alter this, you should copy and paste it verbatim:

   <target name="canonicalise" description="canonicalises adl">
                <style verbose="true" style="${adl-transforms}/adl2canonical.xslt"
                           in="${adl-src}"
                           out="${canonical}">
                        <parameters>
                                <parameter name="abstract-key-name-convention" value="Name_Id"/>
                        </parameters>
                </style>
        </target>

####  Generate NHibernate mapping

You should generally not need to alter this at all, just copy and paste it verbatim:

   <target name="hbm" description="generates  NHibernate mapping for database"
                        depends="canonicalise">
                <style verbose="true" style="${adl-transforms}/adl2hibernate.xslt"
                           in="${canonical}"
                           out="${src.dir}/${project.name}.auto.hbm.xml">
                        <parameters>
                                <parameter name="namespace" value="${entityns}"/>
                                <parameter name="assembly" value="${assembly}"/>
                        </parameters>
                </style>
        </target>

####  Generate SQL

   <target name="sql" description="Generates cadlink database initialisation script"
                        depends="canonicalise">
                <style verbose="true" style="${adl-transforms}/adl2mssql.xslt"
                           in="${canonical}"
                           out="${src.dir}/${project.name}.auto.sql">
                        <parameters>
                                <parameter name="abstract-key-name-convention" value="Name_Id"/>
                                <parameter name="database" value="ESA-McIntosh-CADLink"/>
                        </parameters>
                </style>
        </target>

####  Generate C# entity classes ('POCOs')

Note that for this to work you must have the following:

*   '[Artistic Style](http://astyle.sourceforge.net/ "http://astyle.sourceforge.net/")' installed as `c:\Program Files\astyle\bin\astyle.exe`

   <target name="fetchtasks" depends="prepare"
                  description="fetches our NantTasks library from the well known place where it resides">
                <get src="http://libs.cygnets.co.uk/NantTasks.dll"
                  dest="${nant-tasks}"/>
        </target>

        <target name="classes" description="creates C# classes for entities in the database"
                        depends="fetchtasks canonicalise">
                <loadtasks assembly="${nant-tasks}" />

                <style verbose="true" style="${adl-transforms}/adl2entityclass.xslt"
                           in="${canonical}"
                           out="${tmpdir}/classes.auto.cs">
                        <parameters>
                                <parameter name="locale" value="en-UK"/>
                                <parameter name="controllerns" value="${controllerns}"/>
                                <parameter name="entityns" value="${entityns}"/>
                        </parameters>
                </style>
                <exec program="c:\\Program Files\\astyle\\bin\\astyle.exe"
                        basedir="."
                        commandline="--style=java --indent=tab=4 --indent-namespaces ${tmpdir}/classes.auto.cs"/>
                <split-regex in="${tmpdir}/classes.auto.cs"
                        destdir="${src.dir}/Entities"
                        pattern="cut here: next file '(\[a-zA-Z0-9_.\]*)'"/>
        </target>

####  Generate Monorail controller classes

Note that for this to work you must have

*   '[Artistic Style](http://astyle.sourceforge.net/ "http://astyle.sourceforge.net/")' installed as `c:\Program Files\astyle\bin\astyle.exe`
*   The 'fetchtasks' target from the 'entity classes' stanza, above.

   <target name="controllers" description="creates C# controller classes"
                        depends="fetchtasks canonicalise">
                <loadtasks assembly="${nant-tasks}" />
                <loadtasks assembly="${nant-contrib}" />
                <style verbose="true" style="${adl-transforms}/adl2controllerclasses.xslt"
                           in="${canonical}"
                           out="${tmpdir}/controllers.auto.cs">

                        <parameters>
                                <parameter name="locale" value="en-UK"/>
                                <parameter name="controllerns" value="${controllerns}"/>
                                <parameter name="entityns" value="${entityns}"/>
                                <parameter name="layout-name" value="default"/>
                                <parameter name="rescue-name" value="generalerror"/>
                        </parameters>
                </style>
                <exec program="c:\\Program Files\\astyle\\bin\\astyle.exe"
                        basedir="."
                        commandline="--style=java --indent=tab=4 --indent-namespaces ${tmpdir}/controllers.auto.cs"/>
                <split-regex in="${tmpdir}/controllers.auto.cs"
                                   destdir="${controllers}/Auto" pattern="cut here: next file '(\[a-zA-Z0-9_.\]*)'"/>
        </target>

####  Generate Velocity views for use with Monorail

Note that for this to work you must have

*   The 'fetchtasks' target from the 'entity classes' stanza, above.



   <target name="views" description="creates Velocity templates"
                        depends="fetchtasks canonicalise">
                <loadtasks assembly="${nant-tasks}" />

                <style verbose="true" style="${adl-transforms}/adl2views.xslt"
                           in="${canonical}"
                           out="${tmpdir}/views.auto.vm">
                        <parameters>
                                <parameter name="layout-name" value="default"/>
                                <parameter name="locale" value="en-UK"/>
                                <parameter name="controllerns" value="${controllerns}"/>
                                <parameter name="entityns" value="${entityns}"/>
                                <parameter name="generate-site-navigation" value="false"/>
                                <parameter name="permissions-group" value="partsbookeditors"/>
                                <parameter name="show-messages" value="true"/>
                        </parameters>
                </style>
                <split-regex in="${tmpdir}/views.auto.vm"
                                         destdir="${views}" pattern="cut here: next file '(\[a-zA-Z0-9_./\]*)'"/>
        </target>
