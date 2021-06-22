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

    var shift:Bool = false;
    var knobMode:KnobMode = Volume;

    // main transport section buttons
    private static inline var PLAY_PAUSE =      91;
    private static inline var RECORD =          93;
    private static inline var SHIFT =           98;

    // scene buttons
    private static inline var CLIP_STOP =       82;
    private static inline var SOLO =            83;
    private static inline var REC_ARM =         84;
    private static inline var MUTE =            85;
    private static inline var SELECT =          86;

    // all by itself
    private static inline var STOP_ALL_CLIPS =  81;

    // arrow and knob control section
    private static inline var UP =              64;
    private static inline var DOWN =            65;
    private static inline var LEFT =            66;
    private static inline var RIGHT =           67;
    private static inline var VOLUME =          68;
    private static inline var PAN =             69;
    private static inline var SEND =            70;
    private static inline var DEVICE =          71;

    var midiTriggerList:MidiTriggerList = null;
    var offMidiTriggerList:MidiTriggerList = null;

    public function new()
    {
    }

    private function onMidi(message:MidiMessage, delta:Float):Void
    {
        // We generally ignore notes on channel 1 as those are just for sending direct to the DAW
        if (message.channel == 1) {
            // ...unless it's sustain and shift is already present, in which case, custom function time!
            // if (message.messageType == NoteOn && ) 
            return;
        }
        if (message.messageType == NoteOn) {
            midiTriggerList.handle(message.byte2);
        } else if (message.messageType == NoteOff) {
            offMidiTriggerList.handle(message.byte2);
        }
    }

    private function setupTriggers()
    {
        midiTriggerList = new MidiTriggerList();
        midiTriggerList.push(new SingleNoteTrigger(PLAY_PAUSE, () -> {
            if (shift) transport.tapTempo();
            else transport.play();
        }));
        midiTriggerList.push(new SingleNoteTrigger(RECORD, () -> {
            if (shift) true; // do something like this: cursorRemoteControls.selectNextPage(true);
            else transport.record();
        }));
        midiTriggerList.push(new SingleNoteTrigger(SHIFT, () -> {
            shift = true;
        }));

        offMidiTriggerList = new MidiTriggerList();
        offMidiTriggerList.push(new SingleNoteTrigger(SHIFT, () -> {
            shift = false;
        }));
    }

    public function startup(host_:Host)
    {
        setupTriggers();

        host = host_;

        host.showMessage('startup() called');
        // TODO get knob mode from settings
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