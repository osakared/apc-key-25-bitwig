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
    var midiOut:grig.midi.MidiSender;

    var shift:Bool = false;
    var knobMode:KnobMode = KnobMode.Volume;
    var trackMode:TrackMode = TrackMode.ClipStop;

    var midiTriggerList:MidiTriggerList = null;
    var offMidiTriggerList:MidiTriggerList = null;

    var knobCtrlDisplay:MidiDisplay = null;
    var trackCtrlDisplay:MidiDisplay = null;
    var sceneLaunchDisplay:MidiDisplay = null;

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

        // Transport stuff
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.PlayPause, () -> {
            if (shift) transport.tapTempo();
            else transport.play();
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Record, () -> {
            if (shift) true; // do something like this: cursorRemoteControls.selectNextPage(true);
            else transport.record();
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Shift, () -> {
            shift = true;
        }));

        // Track controls/arrows/knob controls
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Volume, () -> {
            if (shift) knobMode = KnobMode.Volume;
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Pan, () -> {
            if (shift) knobMode = KnobMode.Pan;
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Send, () -> {
            if (shift) knobMode = KnobMode.Send;
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Device, () -> {
            if (shift) knobMode = KnobMode.Device;
        }));

        offMidiTriggerList = new MidiTriggerList();
        offMidiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Shift, () -> {
            shift = false;
        }));
    }

    private function setupDisplays()
    {
        knobCtrlDisplay = new MidiDisplay([[ButtonNotes.Volume, ButtonNotes.Pan, ButtonNotes.Send, ButtonNotes.Device]], TrackButtonMode.Off, 0);
        trackCtrlDisplay = new MidiDisplay([[
            ButtonNotes.Up, ButtonNotes.Down, ButtonNotes.Left, ButtonNotes.Right, ButtonNotes.Volume, ButtonNotes.Pan,
            ButtonNotes.Send, ButtonNotes.Device
        ]], TrackButtonMode.Off, 0);
        sceneLaunchDisplay = new MidiDisplay([[ButtonNotes.ClipStop, ButtonNotes.Solo, ButtonNotes.RecArm, ButtonNotes.Mute, ButtonNotes.Select]],
            SceneButtonMode.Off, 0);
    }

    public function startup(host:Host)
    {
        this.host = host;

        host.showMessage('startup() called');
        setupTriggers();
        setupDisplays();
        // TODO get knob mode from settings
        transport = host.getTransport();
        host.getMidiIn(0).setCallback(onMidi);
        midiOut = host.getMidiOut(0);
    }

    public function shutdown()
    {
        host.showMessage('shutdown() called');
    }

    public function flush()
    {
        if (shift) {
            knobCtrlDisplay.setExclusive(0, knobMode, TrackButtonMode.Red);
            knobCtrlDisplay.display(midiOut);
            sceneLaunchDisplay.setExclusive(0, trackMode, SceneButtonMode.Green);
            sceneLaunchDisplay.display(midiOut);
        } else {
            trackCtrlDisplay.display(midiOut);
            sceneLaunchDisplay.clear();
            sceneLaunchDisplay.display(midiOut);
        }
    }
}