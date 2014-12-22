APC Key 25 Control Script for Bitwig
====================================

Introduction
------------

This is a work-in-progress attempt to get the
[APC Key 25](http://www.akaipro.com/product/apc-key-25) working with [Bitwig](http://www.bitwig.com).

### Difference With Official Ableton Script:

* Shift + "Stop All Clips" returns to arrangement.
* In mute mode, the light indicates that the track IS muted (which makes more sense to me).
* Unimplemented features and issues (see below)

TODO
----

* Finish grid
* Implement the knobs!

### Issues:

* Color/blinking in scene launch buttons doesn't work (the right callbacks don't seem to exist; contact Bitwig about this)

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