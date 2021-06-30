package com.osakared.akai;

import grig.controller.Host;
import grig.midi.MidiMessage;

enum Direction
{
    Left;
    Right;
    Up;
    Down;
}

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
    private static var ARROW_BUTTONS = [[ButtonNotes.Up, ButtonNotes.Down, ButtonNotes.Left, ButtonNotes.Right]];
    private static var SCENE_BUTTONS = [[ButtonNotes.ClipStop, ButtonNotes.Solo, ButtonNotes.RecArm, ButtonNotes.Mute, ButtonNotes.Select]];
    private static var TRACK_BUTTONS = [[ButtonNotes.Up, ButtonNotes.Down, ButtonNotes.Left, ButtonNotes.Right,
                                         ButtonNotes.Volume, ButtonNotes.Pan, ButtonNotes.Send, ButtonNotes.Device]];

    private var host:Host;
    private var midiOut:grig.midi.MidiSender = null;
    private var pages = new Array<{arrowDisplay:MidiDisplay, gridDisplay:MidiDisplay, movable:grig.controller.Movable}>();
    private var pageIndex:Int = 0;

    private var shift:Bool = false;
    private var _knobMode:KnobMode;
    private var knobMode(get, set):KnobMode;

    private var trackCtrlDisplays = new Array<MidiDisplay>();
    private var _trackMode:TrackMode;
    private var trackMode(get, set):TrackMode;

    private var midiTriggerList:MidiTriggerList = null;
    private var offMidiTriggerList:MidiTriggerList = null;

    private var emptyArrowDisplay:MidiDisplay = null;
    private var knobCtrlDisplay:MidiDisplay = null;
    private var trackModeDisplay:MidiDisplay = null;
    private var sceneLaunchDisplay:MidiDisplay = null;

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
        trackModeDisplay.setExclusive(0, _trackMode, SceneButtonMode.Green);
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

    private function setupClipView(clipView:grig.controller.ClipView)
    {
        // Callbacks for arrow displays
        var arrowDisplay = new MidiDisplay(ARROW_BUTTONS, TrackButtonMode.Off, 0);
        clipView.addCanMoveChangedCallback((direction:grig.controller.Direction, canMove:Bool) -> {
            var mode = switch direction {
                case Up: ArrowMode.Up;
                case Down: ArrowMode.Down;
                case Left: ArrowMode.Left;
                case Right: ArrowMode.Right;
            }
            arrowDisplay.set(0, mode, trackButtonModeOn(canMove));
        });

        // Triggers for scene launchers
        midiTriggerList.push(new MultiNoteTrigger(SCENE_BUTTONS[0], (idx:Int) -> {
            if (!shift) clipView.playScene(idx);
        }));

        var gridNotes = new Array<Array<Int>>();
        for (i in 0...HEIGHT) {
            gridNotes.push([for (j in 0...WIDTH) (HEIGHT - i - 1) * 8 + j]);
        }
        var gridDisplay = new MidiDisplay(gridNotes, GridButtonMode.Off, 0);
        clipView.addClipStateUpdateCallback((track:Int, scene:Int, state:grig.controller.ClipState) -> {
            var mode = switch state {
                case Playing: GridButtonMode.Green;
                case Recording: GridButtonMode.Red;
                case Stopped: GridButtonMode.Amber;
                case PlayingQueued: GridButtonMode.BlinkingGreen;
                case RecordingQueued: GridButtonMode.BlinkingRed;
                case StopQueued: GridButtonMode.BlinkingAmber;
                case Empty: GridButtonMode.Off;
            }
            gridDisplay.set(scene, track, mode);
        });

        clipView.addSceneUpdateCallback((track:Int, state:grig.controller.SceneState) -> {
            var mode = switch state {
                case Playing: SceneButtonMode.Green;
                case PlayingQueued: SceneButtonMode.BlinkingGreen;
                case StopQueued: SceneButtonMode.Green;
                case Stopped: SceneButtonMode.Off;
            }
            sceneLaunchDisplay.set(0, track, mode);
        });

        pages.push({arrowDisplay: arrowDisplay, gridDisplay: gridDisplay, movable: clipView});

        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.StopAllClips, () -> {
            if (shift) clipView.returnToArrangement();
            else clipView.stopAllClips();
        }));

        midiTriggerList.push(new GridNoteTrigger(gridNotes, (x:Int, y:Int) -> {
            if (shift) clipView.recordClip(y, x); // let's make this configurable!
            else clipView.playClip(y, x);
        }));
    }

    private function setupTrackView(trackView:grig.controller.TrackView):Void
    {
        for (_ in 0...SCENE_BUTTONS[0].length) {
            trackCtrlDisplays.push(new MidiDisplay(TRACK_BUTTONS, TrackButtonMode.Off, 0));
        }
        
        trackView.addTrackStateUpdateCallback((track:Int, state:grig.controller.TrackState) -> {
            host.logMessage('$track $state');
            var mode = switch state {
                case Playing: TrackButtonMode.Off;
                case StopQueued: TrackButtonMode.BlinkingRed;
                case Stopped: TrackButtonMode.Red;
            }
            trackCtrlDisplays[TrackMode.ClipStop].set(0, track, mode);
        });

        trackView.addIsSoloedCallback((track:Int, soloed:Bool) -> {
            trackCtrlDisplays[TrackMode.Solo].set(0, track, soloed ? TrackButtonMode.Red : TrackButtonMode.Off);
        });

        trackView.addIsArmedCallback((track:Int, isArmed:Bool) -> {
            trackCtrlDisplays[TrackMode.RecArm].set(0, track, isArmed ? TrackButtonMode.Red : TrackButtonMode.Off);
        });

        trackView.addIsMutedCallback((track:Int, muted:Bool) -> {
            trackCtrlDisplays[TrackMode.Mute].set(0, track, muted ? TrackButtonMode.Red : TrackButtonMode.Off);
        });

        trackView.addSelectTrackUpdateCallback((track:Int) -> {
            trackCtrlDisplays[TrackMode.Select].setExclusive(0, track, TrackButtonMode.Red);
        });

        midiTriggerList.push(new MultiNoteTrigger(TRACK_BUTTONS[0], (idx:Int) -> {
            if (!shift) {
                switch trackMode {
                    case ClipStop: trackView.stopTrack(idx);
                    case Solo: trackView.soloTrack(idx);
                    case RecArm: trackView.armTrack(idx);
                    case Mute: trackView.muteTrack(idx);
                    case Select: trackView.selectTrack(idx);
                    default: true;
                }
            }
        }));
    }

    private function movePage(direction:Direction):Void
    {
        if (pages.length == 0) return;

        var page = pages[pageIndex].movable;
        switch (direction) {
            case Left: page.move(Left);
            case Right: page.move(Right);
            case Up: page.move(Up);
            case Down: page.move(Down);
        }
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
            if (shift) movePage(Up);
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Down, () -> {
            if (shift) movePage(Down);
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Left, () -> {
            if (shift) movePage(Left);
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Right, () -> {
            if (shift) movePage(Right);
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
        emptyArrowDisplay = new MidiDisplay(ARROW_BUTTONS, TrackButtonMode.Off, 0);
        knobCtrlDisplay = new MidiDisplay([[ButtonNotes.Volume, ButtonNotes.Pan, ButtonNotes.Send, ButtonNotes.Device]], TrackButtonMode.Off, 0);
        sceneLaunchDisplay = new MidiDisplay(SCENE_BUTTONS, SceneButtonMode.Off, 0);
        trackModeDisplay = new MidiDisplay(SCENE_BUTTONS, SceneButtonMode.Off, 0);
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
                case Failure(error): host.logMessage('Transport unavailable: ${error.message}');
            }
        });
        host.createClipView(WIDTH, HEIGHT).handle((outcome) -> {
            switch outcome {
                case Success(clipView):
                    setupClipView(clipView);
                    setupTrackView(clipView.getTrackView());
                case Failure(error):
                    host.createTrackView(WIDTH).handle((trackOutcome) -> {
                        switch trackOutcome {
                            case Success(trackView): setupTrackView(trackView);
                            case Failure(trackError): host.logMessage('ClipView and TrackView not available:\n\t$error\n\t$trackOutcome');
                        }
                    });
            }
        });
        host.getMidiIn(0).handle((outcome) -> {
            switch outcome {
                case Success(midiIn): midiIn.setCallback(onMidi);
                case Failure(error): host.logMessage('Midi in unavailable: ${error.message}');
            }
        });
        midiOut = host.getMidiOut(0);
        setupDisplays();
        // TODO get knob mode from settings
        knobMode = KnobMode.Volume;
        trackMode = TrackMode.ClipStop;
    }

    public function shutdown()
    {
        host.showMessage('shutdown() called');
    }

    private function displayArrows():Void
    {
        if (pages.length == 0) {
            emptyArrowDisplay.display(midiOut);
            return;
        }
        pages[pageIndex].arrowDisplay.display(midiOut);
    }

    private function displayGrid():Void
    {
        if (pages.length == 0) return;
        pages[pageIndex].gridDisplay.display(midiOut);
    }

    private function displayTrackCtrlDisplays()
    {
        if (trackCtrlDisplays.length == 0) {
            knobCtrlDisplay.displayClear(midiOut);
            emptyArrowDisplay.display(midiOut);
        }
        trackCtrlDisplays[trackMode].display(midiOut);
    }

    public function flush()
    {
        if (shift) {
            displayArrows();
            knobCtrlDisplay.display(midiOut);
            trackModeDisplay.display(midiOut);
        } else {
            sceneLaunchDisplay.display(midiOut);
            displayTrackCtrlDisplays();
        }
        displayGrid();
    }
}