MAZeroingWeakRef - by Mike Ash - mike@mikeash.com

Introduction
------------

MAZeroingWeakRef is a library for using zeroing weak references in retain/release Cocoa and Cocoa Touch code. These are references which do not keep an object alive, and which automatically become nil once the object is destroyed.

MAZeroingWeakRef does not work under Cocoa garbage collection. The built-in __weak specifier exists for that, although it is used somewhat differently.

The API is simple and mostly self-explanatory from the header file. Note that cleanup blocks are only needed for advanced uses when you need to take more action than simply zeroing the reference when the target object is destroyed. Be sure to heed the warning in the header about not doing too much work in the cleanup block.

In order to allow weak references to CoreFoundation bridged objects, a fair amount of crazy hacking of private APIs had to be done. For people who don't like that sort of thing, or who are worried about rejection when building for iOS, this crazy hacking can be reduced or disabled altogether. Look at the COREFOUNDATION_HACK_LEVEL macro in MAZeroingWeakRef.m, and the comment above it which explains what the different levels do.

A similar KVO_HACK_LEVEL macro is also available.

App Store
---------

For iOS work, or Mac App Store work, you will probably want to set both COREFOUNDATION_HACK_LEVEL and KVO_HACK_LEVEL to `0`. In this mode, MAZeroingWeakRef uses no private APIs.

Source Code
-----------

The MAZeroingWeakRef code is available from GitHub:

    http://github.com/mikeash/MAZeroingWeakRef

MAZeroingWeakRef is made available under a BSD license.

More Information
----------------

For more information about it, this blog post gives a basic introduction to the API:

    http://mikeash.com/pyblog/introducing-mazeroingweakref.html

This describes how it works in most cases:

http://mikeash.com/pyblog/friday-qa-2010-07-16-zeroing-weak-references-in-objective-c.html

And this describes some of the more hairy parts:

    http://mikeash.com/pyblog/friday-qa-2010-07-30-zeroing-weak-references-to-corefoundation-objects.html

Enjoy!
