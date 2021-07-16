APC Key 25 Control Script for Bitwig
====================================

Introduction
------------

This is a controller extension for
[APC Key 25](http://www.akaipro.com/product/apc-key-25). Works with [Bitwig](http://www.bitwig.com) and any other DAW supported by grig.controller in the future.

The old javascript-based Bitwig controller script is still here for anyone who wants to use it for now but the haxe/jvm version supercedes it and should be better than it in every way.

### Difference With Official Ableton Script:

* Shift + Sustain toggles lancher vs. matrix keyboard mode
* Shift + clip button records into a clip.
* Shift + "Stop All Clips" returns to arrangement.
* Shift + Play/Pause does tap tempo.
* Shift + Record stops.
* In mute mode, the light indicates that the track _is_ muted.
* Repeatedly pressing Shift + Send cycles through sends
* Repeatedly pressing Shift + Device cycles through device pages

Installation
------------

Copy APCKey25.bwextension into your local extensions directory:

* `~/Documents/Bitwig\ Studio/Extensions/` in macos
* `~/Bitwig Studio/Extensions/` in linux
* `%userprofile%\Documents\Bitwig Studio\Extensions\` in windows

Development
-----------

[![Gitter](https://badges.gitter.im/haxe-grig/Lobby.svg)](https://gitter.im/haxe-grig/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

License
-------

This is licensed under the very permissive MIT license. See LICENSE for more details.
Copyright 2014-2021 Thomas J. Webb and Johan Berntsson
