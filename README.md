APC Key 25 Control Script for Bitwig
====================================

Introduction
------------

This is a controller extension for
[APC Key 25](http://www.akaipro.com/product/apc-key-25). Works with [Bitwig](http://www.bitwig.com) and any other DAW supported by grig.controller in the future.

The old javascript-based Bitwig controller script is still here for anyone who wants to use it for now but the haxe/jvm version supercedes it and should be better than it in every way.

### Difference With Official Ableton Script:

* ~~Shift + Sustain toggles velocity sensitivity on and off.~~
* Shift + Sustain toggles lancher vs. matrix keyboard mode
* Shift + clip button deletes a clip when in rec/arm mode.
* Shift + "Stop All Clips" returns to arrangement.
* Shift + Play/Pause does tap tempo.
* Shift + Record depends on knob mode:
  * Cycles through send in send mode
  * Cycles through remote pages in device mode
* In mute mode, the light indicates that the track _is_ muted.

### Nice to Haves:

* Ability to remap Shift + [Sustain, Play/Pause, Rec] since there are more features we could add than just the three and different people have different workflows
* Marquee/image mode (like Bitwig logo or APC on startup)
* Ability to use clip launchers as a keyboard (with selectable modes)

Installation
------------

Copy APCKey25.bwextension into your local extensions directory:

* `~/Documents/Bitwig\ Studio/Extensions/` in macos
* `~/Bitwig Studio/Extensions/` in linux
* `%userprofile%\Documents\Bitwig Studio\Extensions\` in windows

License
-------

This is licensed under the very permissive MIT license. See LICENSE for more details.
Copyright 2014-2021 Thomas J. Webb and Johan Berntsson
