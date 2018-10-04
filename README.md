# Application Description Language

A language for describing applications, from which code can be automatically generated.

[![Clojars Project](https://img.shields.io/clojars/v/adl.svg)](https://clojars.org/adl)

## Contents

1. [Usage](#user-content-usage)
2. [History](#user-content-history)
3. [Why this is a good idea](#user-content-why-this-is-a-good-idea)
4. [What exists](#user-content-what-exists)
5. [Future direction](#user-content-future-direction)
6. [Contributing](#user-content-contributing)


## Usage

A document describing the proposed application should be written in XML using the DTD `resources/schemas/adl-1.4.1.dtd`. It may then be transformed into a C# or Java application using the XSL transforms, see **History** below, but this code is very out of date and the resulting application is unlikely to be very usable.

### Clojure

Alternatively, it can be transformed into a Clojure [Luminus](http://www.luminusweb.net/) application using the Clojure transformation, as follows:

    simon@fletcher:~/workspace/adl$ java -jar target/adl-[VERSION]-standalone.jar --help
    Usage: java -jar adl-[VERSION]-standalone.jar -options [adl-file]
    where options include:
      -a, --abstract-key-name-convention [string]: the abstract key name convention to use for generated key fields (TODO: not yet implemented); (default: id)
      -h, --help: Show this message
      -l, --locale [LOCALE]: set the locale to generate; (default: en_GB.UTF-8)
      -p, --path [PATH]: The path under which generated files should be written; (default: generated)
      -v, --verbosity [LEVEL], : Verbosity level - integer value required; (default: 0)

Of more simply using the [leiningen](https://leiningen.org/) plugin, see [lein-adl](https://github.com/simon-brooke/lein-adl).

#### What is generated for Clojure

The following files are generated:

* `resources/sql/queries.auto.sql` - [HugSQL](https://www.hugsql.org/) queries for selection, insertion, modification and deletion of records of all entities described in the ADL file.
* `resources/sql/[application-name].postgres.sql` - [Postgres](https://www.postgresql.org/) database initialisation script including tables for all entities, convenience views for all entities, all necessary link tables and referential integrity constraints.
* `resources/templates/auto/*.html` - [Selmer](https://github.com/yogthos/Selmer) templates for each form or list list specified in the ADL file (pages are not yet handled).
* `src/clj/[application-name]/routes/auto.clj` - [Compojure]() routes for each form or list list specified in the ADL file (pages are not yet handled).
* `src/clj/[application-name]/routes/auto-json.clj` - [Compojure]() routes returning JSON responses for each query generated in `resources/sql/queries.auto.sql`.

*You are strongly advised never to edit any of these files*.

* To override any query, add that query to a file `resources/sql/queries.sql`
* To add additional material (for example reference data) to the database initialisation, add it to a separate file or a family of separate files.
* To override any template, copy the template file from `resources/templates/auto/` to `resources/templates/` and edit it there.
* To override any route, write a function of the same name in the namespace `[application-name].routes.manual`.

#### Some assembly required

It would be very nice to be able to type

    lein new luminus froboz +adl

and have a new Luminus project initialised with a skeleton ADL file, and all the glue needed to make it work, already in place. [This is planned](https://github.com/simon-brooke/adl/issues/6), but just at present it isn't there and you will have to do some work yourself.

Where, in `src/clj/[application-name]/db/core.clj` [Luminus]() would autogenerate

    (conman/bind-connection *db* "sql/queries.sql")

You should substitute

    (conman/bind-connection *db* "sql/queries.auto.sql" "sql/queries.sql")
    (hugsql/def-sqlvec-fns "sql/queries.auto.sql")

You should add the following two stanzas to the `app-routes` definition in `src/clj/[project-name]/handler.clj`.

    (-> #'auto-rest-routes
        (wrap-routes middleware/wrap-csrf)
        (wrap-routes middleware/wrap-formats))
    (-> #'auto-selmer-routes
        (wrap-routes middleware/wrap-csrf)
        (wrap-routes middleware/wrap-formats))

Finally, you should prepend `"adl"` to the vector of `prep-tasks` in the `uberjar` profile of you `project.clj` file, thus:

    :profiles {:uberjar {:omit-source true
                         :prep-tasks ["adl"
                                      "compile"
                                      ["npm" "install"]
                                      ["cljsbuild" "once" "min"]]
                         ...

The above assumes you are using Luminus to initialise your project; if you are not, then I expect that you are confident enough using Clojure that you can work out where these changes should be made in your own code.

## History

This idea started back in 2007, when I felt that web development in Java had really reached the end of the road - one spent all one's time writing boilerplate, and the amount of time taken to achieve anything useful had expanded far beyond common sense. So I thought: write one high level document describing an application; write a series of transforms from that document to the different files required to build the application; and a great deal of time would be saved.

And this worked. When it was used commercially, the target language was mostly C#, which I don't much like, but...

Then, in 2010, I had one of my periodic spells of mental illness, and development stopped. Later, when my former employers ceased to develop software, copyright in the project was turned over to me.

More recently, I've found myself in the same situation with Clojure that I was in 2007 with Java: I'm writing fairly large applications and the amount of mindless boilerplate that has to be written is a real problem. So I'm looking at reviving this old framework and bringing it up to date.

## Why this is a good idea

Web applications contain an awful lot of repetitive code. Not only does this take a lot of time to write; when you have an awful lot of repetitive code, if you find a bug in one place and fix it, it also probably has to be found and fixed in many other places. Also, underlying libraries, frameworks and (sometimes) even languages have breaking changes from one version to the next. Fixing the issue in the code generator, and then automatically regenerating the code for all of your applications, is enormously quicker than finding and fixing the issues in each file of each application separately.

Also, you can port all your applications to new technologies simply by writing transforms for those new technologies and regenerating.

The idea is that the ADL framework should autogenerate 95% of your application. This means human programmer effort can be concentrated on the 5% which is actually interesting.

## What exists

### The DTD

A Document Type Definition is the core of this; the current version is `adl-1.4.1.dtd`.

### The Clojure transformer application

This is the future direction of the project. Currently it converts a valid ADL XML document into most of the files required for a Clojure web-app. Shortly it will produce a complete Clojure [Luminus](http://www.luminusweb.net/) web-app. In future it may produce web-apps in other languages and frameworks.

### A Leiningen plugin

A [Leiningen](https://leiningen.org) plugin is available.

### XSL transforms

XSL transforms exist which transform conforming documents as follows:

* `adl2activerecord.xslt` - generate C# ActiveRecord classes
* `adl2canonical.xslt` - canonicalises ADL, adding useful defaults
* `adl2controllerclasses.xslt` - generates C# controller classes
* `adl2documentation.xslt` - generates documentation
* `adl2entityclasses.xslt` - generates C# entity classes
* `adl2hibernate.xslt` - generates [N]Hibernate mapping files
* `adl2mssql.xslt` - generates Microsoft SQL Server database initialisation scripts
* `adl2psql.xslt` - generates Postgres database initialisation scripts
* `adl2views.xslt` - generates Velocity templates

All of this worked (well) back in 2010, but it relied on some proprietary libraries which are not my copyright. So you can't just pick it up and use it. But it provides a basis for writing new transforms in XSL, should you choose to do so.

## Future direction

Back in 2007, XSLT seemed a really good technology for doing this sort of thing. But it's prolix, and while back then I was expert in it, I don't really use it much now. So my plan is to write future transforms in Clojure, and, because these days I work mostly in Clojure, the transforms I shall write will mostly target the Clojure ecosystem.

Ultimately ADL will probably transition from XML to [EDN](https://github.com/edn-format/edn).

I plan to generate a [re-frame](https://github.com/Day8/re-frame) skeleton, to support client side and [React Native](https://facebook.github.io/react-native/) applications, but this is not yet in place.

This doesn't mean you can't pick up the framework and write transforms in other languages and/or to other language ecosystems. In fact, I'd encourage you to do so.

## Contributing

I will happily accept pull requests for new XSL transforms (although I'd like some evidence they work). I'll also happily accept pull requests for new transforms written in Clojure. Changes to the DTD I shall be more conservative about, simply because there is a potential to break a lot of stuff and the DTD is fairly good. All schemas are generated off the DTD using `[trang](https://github.com/relaxng/jing-trang)`, so there is no point in sending pull requests on schema changes.

## License

Copyright © Simon Brooke 2007-2018; some work was done under contract to [Cygnet Solutions Ltd](http://cygnets.co.uk/), but they have kindly transferred the copyright back to me.

Distributed under the Gnu LGPL version 3 or any later version; I am open to licensing this project under additional licences if required.
