package com.osakared.akai;

import grig.controller.Host;

@name("APC Key 25 mk2")
@author("pinkboi")
@version("1.4")
@uuid("9eb1c1d4-9aad-11ed-a250-b3aa386a7565")
@hardwareVendor("Akai")
@hardwareModel("APC Key 25 mk2")
@numMidiInPorts(1)
@numMidiOutPorts(1)
@deviceNamePairs([["APC Key 25 mk2 C"], ["APC Key 25 mk2 C"]], [["APC Key 25 mk2 APC Key 25 mk2 C"], ["APC Key 25 mk2 APC Key 25 mk2 C"]])
class APCKey25Mk2Controller implements grig.controller.Controller
{
    private var controller = new APCKey25(Mk2);

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