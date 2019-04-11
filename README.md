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

-osakared

I didn't like the velocity response so I added a velocity sensitivity 
switch. Use shift+sustain to toggle on and off.

- Johan Berntsson

### Difference With Official Ableton Script:

* Shift + Sustain toggles velocity sensitivity on and off.
* Shift + "Stop All Clips" returns to arrangement.
* In mute mode, the light indicates that the track _is_ muted (which makes more sense to me).
* The issue below

### Issues:

* Number of sends hard-coded to 10 since the sends functionality doesn't seem to be implemented right in the Bitwig api

### Nice to Haves:

* Additional banks of device knobs
* Marquee/image mode (like Bitwig logo or APC on startup)
* Ability to use clip launchers as a keyboard (with selectable modes)

Installation
------------

Copy the APCKey25.control.js script into the akai folder in controllers
(e.g., /opt/bitwig-studio/resources/controllers/akai/ in linux).

License
-------

This is licensed under the very permissive BSD license. See LICENSE for more details.
Copyright 2014-2019 Osaka Red LLC, Thomas J. Webb and Johan Berntsson
