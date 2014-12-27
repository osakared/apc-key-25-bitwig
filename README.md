APC Key 25 Control Script for Bitwig
====================================

Introduction
------------

This is my attempt at getting
[APC Key 25](http://www.akaipro.com/product/apc-key-25) working with [Bitwig](http://www.bitwig.com).
The goal is to get it doing everything the official script does, plus more. Turn this affordable
piece of gear into a powerhouse with Bitwig and this script!

So far, it's mostly working other than the issues noted below. It would be nice to someday add
additional features seen under "Nice to Haves".

### Difference With Official Ableton Script:

* Shift + "Stop All Clips" returns to arrangement.
* In mute mode, the light indicates that the track IS muted (which makes more sense to me).
* The issues below

### Issues:

* Doesn't properly support multiple sends (just goes with the first send, if it even exists)
* Color/blinking in scene launch buttons doesn't work (the right callbacks don't seem to exist; contact Bitwig about this)

### Nice to Haves:

* Additional banks of device knobs (i.e., get all of the midi cc messages somehow)
* Marquee/image mode (like Bitwig logo or APC on startup)
* Ability to use clip launchers as a keyboard (with selectable modes)
* Let user assign knobs

Installation
------------

Copy the APCKey25.control.js script into the akai folder in controllers
(e.g., /opt/bitwig-studio/resources/controllers/akai/ in linux)

License
-------

This is licensed under the very permissive BSD license. See LICENSE for more details.
Copyright 2014 Osaka Red LLC and Thomas J. Webb
