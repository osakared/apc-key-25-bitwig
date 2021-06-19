package com.osakared.akai;

import grig.controller.Host;
import grig.midi.MidiMessage;

@name("APC Key 25")
@author("pinkboi")
@version("1.3")
@uuid("65176610-873b-11e4-b4a9-0800200c9a66")
@hardwareVendor("Akai")
@hardwareModel("APC Key 25")
@numMidiInPorts(1)
@numMidiOutPorts(1)
@deviceNamePairs([["APC Key 25"], ["APC Key 25"]], [["APC Key 25 MIDI 1"], ["APC Key 25 MIDI 1"]])
class APCKey25Controller implements grig.controller.Controller
{
    var host:Host;
    var transport:grig.controller.Transport;

    public function new()
    {
    }

    private function onMidi(message:MidiMessage, delta:Float):Void
    {
        if (message.messageType == NoteOn) {
            switch (message.byte2) {
                case 91: transport.play();
                case 93: transport.record();
            }
            transport.play();
        }
    }

    public function startup(host_:Host)
    {
        host = host_;

        host.showMessage('startup() called');
        transport = host.getTransport();
        host.getMidiIn(0).setCallback(onMidi);
    }

    public function shutdown()
    {
        host.showMessage('shutdown() called');
    }

    public function flush()
    {
    }
}