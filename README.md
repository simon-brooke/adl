# Application Description Language

A language for describing applications, from which code can be automatically generated.

## Usage

A document describing the proposed application should be written in XML using the DTD `resources/schemas/adl-1.4.1.dtd`. It may then be transformed into a C# or Java application using the XSL transforms, see **History** below, but this code is very out of date and the resulting application is unlikely to be very usable. Alternatively, it can be transformed into a Clojure [Luminus](http://www.luminusweb.net/) application using the Clojure transformation, as follows:

    simon@fletcher:~/workspace/adl$ java -jar target/adl-1.4.1-SNAPSHOT-standalone.jar --help
    Usage: java -jar adl-[VERSION]-SNAPSHOT-standalone.jar -options [adl-file]
    where options include:
      -a, --abstract-key-name-convention [string]: the abstract key name convention to use for generated key fields (TODO: not yet implemented); (default: id)
      -h, --help: Show this message
      -l, --locale [LOCALE]: set the locale to generate; (default: en_GB.UTF-8)
      -p, --path [PATH]: The path under which generated files should be written; (default: generated)
      -v, --verbosity [LEVEL], : Verbosity level - integer value required; (default: 0)

This is not yet complete but it is at an advanced stage and already produces code which is useful.

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

A Document Type Definition is the core of this; the current version is `adl-1.4.dtd`.

### The Clojure transformer application

This is the future direction of the project. Currently it converts a valid ADL XML document into most of the files required for a Clojure web-app. Shortly it will produce a complete Clojure [Luminus](http://www.luminusweb.net/) web-app. In future it may produce web-apps in other languages and frameworks.

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

This doesn't mean you can't pick up the framework and write transforms in other languages and/or to other language ecosystems. In fact, I'd encourage you to do so.

## Contributing

I will happily accept pull requests for new XSL transforms (although I'd like some evidence they work). I'll also happily accept pull requests for new transforms written in Clojure. Changes to the DTD I shall be more conservative about, simply because there is a potential to break a lot of stuff and the DTD is fairly good. All schemas are generated off the DTD using `[trang](https://github.com/relaxng/jing-trang)`, so there is no point in sending pull requests on schema changes.

## License

Copyright © Simon Brooke 2007-2018; some work was done under contract to Cygnet Solutions Ltd, but they have kindly transferred the copyright back to me.

Distributed under the Gnu GPL version 2 or any later version; I am open to licensing this project under additional licences if required.
