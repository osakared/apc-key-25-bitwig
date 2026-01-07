package com.osakared.akai;

import grig.controller.Host;

@name("APC Key 25")
@author("pinkboi")
@version("1.5")
@uuid("65176610-873b-11e4-b4a9-0800200c9a66")
@hardwareVendor("Akai")
@hardwareModel("APC Key 25")
@numMidiInPorts(1)
@numMidiOutPorts(1)
@deviceNamePairs([["APC Key 25"], ["APC Key 25"]], [["APC Key 25 MIDI 1"], ["APC Key 25 MIDI 1"]])
class APCKey25Controller implements grig.controller.Controller
{
    private var controller = new APCKey25(Mk1);

    public function new() {}

    public function startup(host:Host) {
        controller.startup(host);
    }

    public function shutdown() {
        controller.shutdown();
    }

    public function flush() {
        controller.flush();
    }
}