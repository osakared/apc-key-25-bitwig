APC Key 25 Control Script for Bitwig
====================================

Introduction
------------

This is a work-in-progress attempt to get the
[APC Key 25](http://www.akaipro.com/product/apc-key-25) working with [Bitwig](http://www.bitwig.com).

TODO
----

* Finish grid
* Implement arrow buttons
* Implement the knobs!
* Implement color in scene launch buttons (the right callbacks don't seem to ask; contact Bitwig about this)

### Nice to Haves:

* Additional banks of device knobs (i.e., get all 127 midi knobs somehow)
* Marquee/image mode
* Ability to use clip launchers as a keyboard (with selectable modes)
* Shift - stop all clips should return to arrangement (really easy to implement)

Installation
------------

Copy the APCKey25.control.js script into the akai folder in controllers
(e.g., /opt/bitwig-studio/resources/controllers/akai/ in linux)

License
-------

This is licensed under the very permissive BSD license. See LICENSE for more details.
Copyright 2014 Osaka Red LLC and Thomas J. Webb