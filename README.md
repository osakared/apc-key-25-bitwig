APC Key 25 Control Script for Bitwig
====================================

Introduction
------------

This is a controller extension for
[APC Key 25](http://www.akaipro.com/product/apc-key-25) and [APC Key 25 mk2](https://www.akaipro.com/apc-key-25-mkii). Works with [Bitwig](http://www.bitwig.com) and ultimately any other DAW supported by [grig.controller](https://gitlab.com/haxe-grig/grig.controller).

### Difference With Official Ableton Script:

* Shift + Sustain toggles lancher vs. matrix keyboard mode
* Shift + clip button records into a clip.
* Shift + "Stop All Clips" returns to arrangement.
* Shift + Play/Pause does tap tempo.
* Shift + Record stops.
* Shift + Knob causes increments to be faster (mk2-only)
* In mute mode, the light indicates that the track _is_ muted.
* Repeatedly pressing Shift + Send cycles through sends
* Repeatedly pressing Shift + Device cycles through device pages

Installation
------------

Get latest [release on github](https://github.com/osakared/apc-key-25-bitwig/releases). Copy APCKey25.bwextension into your local extensions directory:

* `~/Documents/Bitwig\ Studio/Extensions/` in macos
* `~/Bitwig Studio/Extensions/` in linux
* `%userprofile%\Documents\Bitwig Studio\Extensions\` in windows

Development
-----------

[![Gitter](https://badges.gitter.im/haxe-grig/Lobby.svg)](https://gitter.im/haxe-grig/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

There are some extra steps needed to build right now. I'm working on making it super simple. Use the above gitter link to join the channel for the grig project, which grig.controller is a part of and this is the initial script based thereof.

## Bitwig

Have maven installed, then run:

`./scripts/fetch-bitwig-dependencies.sh`

This will install the Bitwig controller api into your local maven repo, which the included `bitwig-maven.hxml` should point to. Then run `haxe build-bitwig.hxml` to build the extension, which will be found at `bin/APCKey25.bwextension`.

License
-------

This is licensed under the very permissive MIT license. See LICENSE for more details.
Copyright 2014-2023 Thomas J. Webb and Johan Berntsson
