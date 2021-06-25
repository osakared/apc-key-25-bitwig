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
    private static inline var WIDTH:Int = 8;
    private static inline var HEIGHT:Int = 5;

    var host:Host;
    var midiOut:grig.midi.MidiSender;
    var clipView:grig.controller.ClipView;

    var shift:Bool = false;
    var _knobMode:KnobMode;
    var knobMode(get, set):KnobMode;
    var _trackMode:TrackMode;
    var trackMode(get, set):TrackMode;

    var midiTriggerList:MidiTriggerList = null;
    var offMidiTriggerList:MidiTriggerList = null;

    var arrowDisplay:MidiDisplay = null;
    var knobCtrlDisplay:MidiDisplay = null;
    var trackCtrlDisplay:MidiDisplay = null;
    var trackModeDisplay:MidiDisplay = null;
    var sceneLaunchDisplay:MidiDisplay = null;

    private function get_knobMode():KnobMode
    {
        return _knobMode;
    }

    private function set_knobMode(_knobMode:KnobMode):KnobMode
    {
        this._knobMode = _knobMode;
        knobCtrlDisplay.setExclusive(0, _knobMode, TrackButtonMode.Red);
        return this._knobMode;
    }

    private function get_trackMode():TrackMode
    {
        return _trackMode;
    }

    private function set_trackMode(_trackMode:TrackMode):TrackMode
    {
        this._trackMode = _trackMode;
        sceneLaunchDisplay.setExclusive(0, _trackMode, SceneButtonMode.Green);
        return this._trackMode;
    }

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

    static private function trackButtonModeOn(value:Bool)
    {
        return if (value) TrackButtonMode.Red;
        else TrackButtonMode.Off;
    }

    private function setupCallbacks()
    {
        clipView.onCanMoveDownChanged((value:Bool) -> {
            arrowDisplay.set(0, ArrowMode.Down, trackButtonModeOn(value));
        });
        clipView.onCanMoveUpChanged((value:Bool) -> {
            arrowDisplay.set(0, ArrowMode.Up, trackButtonModeOn(value));
        });
        clipView.onCanMoveLeftChanged((value:Bool) -> {
            arrowDisplay.set(0, ArrowMode.Left, trackButtonModeOn(value));
        });
        clipView.onCanMoveRightChanged((value:Bool) -> {
            arrowDisplay.set(0, ArrowMode.Right, trackButtonModeOn(value));
        });
    }

    private function setupTriggers()
    {
        midiTriggerList = new MidiTriggerList();

        // Transport stuff
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Shift, () -> {
            shift = true;
        }));

        // Track controls/arrows/knob controls
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Up, () -> {
            if (shift) clipView.moveUp();
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Down, () -> {
            if (shift) clipView.moveDown();
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Left, () -> {
            if (shift) clipView.moveLeft();
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Right, () -> {
            if (shift) clipView.moveRight();
        }));
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

        // Scene controls
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.ClipStop, () -> {
            if (shift) trackMode = TrackMode.ClipStop;
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Solo, () -> {
            if (shift) trackMode = TrackMode.Solo;
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.RecArm, () -> {
            if (shift) trackMode = TrackMode.RecArm;
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Mute, () -> {
            if (shift) trackMode = TrackMode.Mute;
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Select, () -> {
            if (shift) trackMode = TrackMode.Select;
        }));

        offMidiTriggerList = new MidiTriggerList();
        offMidiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Shift, () -> {
            shift = false;
        }));
    }

    private function setupDisplays()
    {
        arrowDisplay = new MidiDisplay([[ButtonNotes.Up, ButtonNotes.Down, ButtonNotes.Left, ButtonNotes.Right]], TrackButtonMode.Off, 0);
        knobCtrlDisplay = new MidiDisplay([[ButtonNotes.Volume, ButtonNotes.Pan, ButtonNotes.Send, ButtonNotes.Device]], TrackButtonMode.Off, 0);
        trackCtrlDisplay = new MidiDisplay([[
            ButtonNotes.Up, ButtonNotes.Down, ButtonNotes.Left, ButtonNotes.Right, ButtonNotes.Volume, ButtonNotes.Pan,
            ButtonNotes.Send, ButtonNotes.Device
        ]], TrackButtonMode.Off, 0);
        var sceneButtons = [[ButtonNotes.ClipStop, ButtonNotes.Solo, ButtonNotes.RecArm, ButtonNotes.Mute, ButtonNotes.Select]];
        sceneLaunchDisplay = new MidiDisplay(sceneButtons, SceneButtonMode.Off, 0);
        trackModeDisplay = new MidiDisplay(sceneButtons, SceneButtonMode.Off, 0);
    }

    private function setupTransport(transport:grig.controller.Transport)
    {
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.PlayPause, () -> {
            if (shift) transport.tapTempo();
            else transport.play();
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Record, () -> {
            if (shift) true; // do something like this: cursorRemoteControls.selectNextPage(true);
            else transport.record();
        }));
    }

    public function startup(host:Host)
    {
        this.host = host;

        host.showMessage('startup() called');
        setupTriggers();
        host.getTransport().handle((outcome) -> {
            switch outcome {
                case Success(transport): setupTransport(transport);
                case Failure(error): trace(error);
            }
        });
        clipView = host.createClipView(WIDTH, HEIGHT);
        host.getMidiIn(0).setCallback(onMidi);
        midiOut = host.getMidiOut(0);
        setupDisplays();
        setupCallbacks();
        // TODO get knob mode from settings
        knobMode = KnobMode.Volume;
        trackMode = TrackMode.ClipStop;
    }

    public function shutdown()
    {
        host.showMessage('shutdown() called');
    }

    public function flush()
    {
        if (shift) {
            arrowDisplay.display(midiOut);
            knobCtrlDisplay.display(midiOut);
            sceneLaunchDisplay.display(midiOut);
        } else {
            trackCtrlDisplay.display(midiOut);
            trackModeDisplay.display(midiOut);
        }
    }
}