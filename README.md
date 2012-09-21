FireBreath JSAPI IDL compiler
=============================

I got tired once of rewriting the code that converts my classes to FB::variant
to be passed from C++ to Javascript in a plugin, so I wrote this class
generator.

First, you create a YAML file with the class definitions (see
[`example/FireBreath_JSAPI_IDL_example.yaml`](FireBreath-JSAPI-IDL/blob/master/example/FireBreath_JSAPI_IDL_example.yaml)).
Then run the JSAPI_IDL_compiler.py and put the YAML file as argument, it will
generate your cpp, h, js files.

Runtime requirements
--------------------

- python-yaml

Documentation and example
-------------------------

Have look in example/ directory. The file
[`example/FireBreath_JSAPI_IDL_example.yaml`](FireBreath-JSAPI-IDL/blob/master/example/FireBreath_JSAPI_IDL_example.yaml)
is the YAML source. In the example dir, there are also generated files (so that
people can look without having to checkout the code and run it).

The sample YAML file shows what constructs you can use and documents how to use
each of them.

How to use in your code
-----------------------

In C++, the generated classes can be used like: 

    #include "example/generated_FireBreath_JSAPI_IDL_example.h"

    using MyNamespace::JSAPIClass;

    FB::variant MyObjectAPI::myExposedRegisteredMethod()
    {
        JSAPIClass c; // default no-data constructor
        JSAPIClass c(value1, value2, ...) // set all values in constructor

        someVar = c.member1.submember2 //access to members

        return someVar.toVariant() // generate FB::variant to pass to javascript
    }

In javascript, the classes will appear like common JS objects, e.g.

    var c = plugin().myExposedRegisteredMethod() //get the result of a plugin call
    var something = c.member1.submember2 + 42; // do something with data

### Subclassing generated classes

You can also subclass the generated toplevel class to add methods:

    class DoesMagic: public MyNamespace::JSAPIClass
    {
    public:
        DoesMagic();

        //for example, you can add a derived value of a member to be seen in JS
        FB::variant toVariant() const
        {
            FB::variant parentVariant = MyNamespace::JSAPIClass::toVariant();
            parentVariant["magic"] = automagically(memberDesperatelyNeedingMagic);
        }
    };

If you subclass non-toplevel classes, you might run into issues with assigning
non-refs and non-pointers, depending on how your code uses the generated and
subclassed structures. It's obviously possible to solve it by defining an extra
constructor, assignment operator or template doing the conversion.


Gotchas/known bugs
------------------

- So far C++ to JS (i.e. class to FB::variant) is implemented, I didn't need
  the other direction. That means you can still pass the generated JS object
  to C++, just the "nice part where it turns to classic C++ class" is not done,
  (you still have a FB::variant).
  - Shouldn't be hard to add though (just check that variant is a map with
    right members, check each member and its type/value recursively)
- Passing std::string containing 0x00 char from C++ to JS doesn't seem to work
  (I get just empty string in JS). Encode those in hex/base64 or something.
- Passing strings from JS to C++: watch out for Unicode and encoding stuff.
  Seems that 0x00 char can be passed this way (but watch out for javascript
  Blob type, that one doesn't work). 
- It'd be nice if we could specialize `FB::variant_detail::conversion::make_variant` for
  our custom generated types, but I didn't find a way how. I guess the
  "specialization-after-instantiation is forbidded/doesn't work in C++" is the
  reason (similarly for overloading `make_variant`).
- Transforming of pointers is not implemented (i.e. no support for pointers as members).

Notes
-----

After generating the .h/.cpp code file, you need FireBreath's `prepXXX`-scripts
if the generated files didn't exist before.

If you use Makefile-based system, for keeping the dependencies of YAML file,
generated files, you can use an analogy of following in Makefile:

    .PHONY: prepmake
    
    GENERATED_SOURCE_FILES := IDLFile.h IDLFILE.cpp
    GENERATED_JS_FILES := IDLFile.js
    GENERATED_FILES := $(GENERATED_SOURCE_FILES) $(GENERATED_JS_FILES)
    
    $(GENERATED_FILES): IDL_definition.yaml
            python JSAPI_IDL_compiler.py $<
    
    #prepmake dependency so that it won't miss sources for building
    prepmake: $(GENERATED_SOURCE_FILES)
            (cd FireBreath && ./prepmake.sh)


