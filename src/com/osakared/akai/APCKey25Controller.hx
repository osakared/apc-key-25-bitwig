package com.osakared.akai;

import grig.controller.display.MidiDisplay;
import grig.controller.Host;
import grig.controller.Movable;
import grig.midi.MidiMessage;
import grig.midi.MidiSender;

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
    private static inline var LOWEST_CC = 48;

    private static var ARROW_BUTTONS = [[ButtonNotes.Up, ButtonNotes.Down, ButtonNotes.Left, ButtonNotes.Right]];
    private static var SCENE_BUTTONS = [[ButtonNotes.ClipStop, ButtonNotes.Solo, ButtonNotes.RecArm, ButtonNotes.Mute, ButtonNotes.Select]];
    private static var TRACK_BUTTONS = [[ButtonNotes.Up, ButtonNotes.Down, ButtonNotes.Left, ButtonNotes.Right,
                                         ButtonNotes.Volume, ButtonNotes.Pan, ButtonNotes.Send, ButtonNotes.Device]];

    private var gridNotes:Array<Array<Int>>;
    private var gridDisplayTable:grig.controller.display.MidiDisplayTable = {
        defaultOnState: GridButtonMode.Green,
        altOnState: GridButtonMode.Amber,
        offState: GridButtonMode.Off,
        playingState: GridButtonMode.Green,
        recordingState: GridButtonMode.Red,
        stoppedState: GridButtonMode.Amber,
        playingQueuedState: GridButtonMode.BlinkingGreen,
        recordingQueuedState: GridButtonMode.BlinkingRed,
        stopQueuedState: GridButtonMode.BlinkingAmber
    };

    private var host:Host;
    private var pages = new Array<{arrowDisplay:MidiDisplay, gridWidget:grig.controller.display.GridWidget}>();
    private var pageIndex:Int = 0;

    private var shift:Bool = false;
    private var _knobMode:KnobMode;
    private var knobMode(get, set):KnobMode;

    private var trackCtrlDisplays = new Array<MidiDisplay>();
    private var _trackMode:TrackMode;
    private var trackMode(get, set):TrackMode;

    private var midiTriggerList = new MidiTriggerList();
    private var offMidiTriggerList = new MidiTriggerList();
    private var ctrlMidiTriggerList = new MidiTriggerList();

    private var midiScreen = new grig.controller.display.MidiScreen();
    private var emptyArrowDisplay:MidiDisplay = null;
    private var knobCtrlDisplay:MidiDisplay = null;
    private var trackModeDisplay:MidiDisplay = null;
    private var sceneLaunchDisplay:MidiDisplay = null;

    // Stuff we can't rely on being filled since it comes from promises
    private var sends = new Array<grig.controller.SendView>();
    private var parameterView:grig.controller.ParameterView = null;
    private var midiOut:grig.midi.MidiSender = null;

    private function get_knobMode():KnobMode
    {
        return _knobMode;
    }

    private function set_knobMode(_knobMode:KnobMode):KnobMode
    {
        if (this._knobMode == _knobMode && _knobMode == KnobMode.Send) {
            for (send in sends) send.cycle();
            return this._knobMode;
        }
        if (this._knobMode == _knobMode && _knobMode == KnobMode.Device) {
            if (parameterView != null) parameterView.cycle();
            return this._knobMode;
        }
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
            // ...unless it's sustain and shift is already present, in which case, custom page time!
            if (shift && message.messageType == ControlChange && message.controlChangeType == Sustain && message.byte3 == 0x7f) {
                if (pages.length < 2) return;
                pageIndex++;
                if (pageIndex >= pages.length) pageIndex = 0;
                host.showMessage('Page: ${pages[pageIndex].gridWidget.getTitle()}');
            } 
            return;
        }
        if (message.messageType == NoteOn) {
            midiTriggerList.handle(message);
        } else if (message.messageType == NoteOff) {
            offMidiTriggerList.handle(message);
        } else if (message.messageType == ControlChange) {
            ctrlMidiTriggerList.handle(message);
        }
    }

    static private function trackButtonModeOn(value:Bool)
    {
        return if (value) TrackButtonMode.Red;
        else TrackButtonMode.Off;
    }

    static private function connectMovableToArrows(movable:Movable, arrowDisplay:MidiDisplay):Void
    {
        movable.addCanMoveChangedCallback((direction:grig.controller.Direction, canMove:Bool) -> {
            var mode = switch direction {
                case Up: ArrowMode.Up;
                case Down: ArrowMode.Down;
                case Left: ArrowMode.Left;
                case Right: ArrowMode.Right;
            }
            arrowDisplay.set(0, mode, trackButtonModeOn(canMove));
        });
    }

    private function setupClipView(clipView:grig.controller.ClipView)
    {
        // Callbacks for arrow displays
        var arrowDisplay = new MidiDisplay(ARROW_BUTTONS, TrackButtonMode.Off, 0);
        connectMovableToArrows(clipView, arrowDisplay);

        // Triggers for scene launchers
        midiTriggerList.push(new MultiNoteTrigger(SCENE_BUTTONS[0], (idx:Int, _:Int) -> {
            if (!shift) clipView.playScene(idx);
        }));

        var gridDisplay = new MidiDisplay(gridNotes, GridButtonMode.Off, 0);
        var clipLauncher = new grig.controller.display.ClipLauncher(gridDisplay, gridDisplayTable, clipView);

        clipView.addSceneUpdateCallback((track:Int, state:grig.controller.SceneState) -> {
            var mode = switch state {
                case Playing: SceneButtonMode.Green;
                case PlayingQueued: SceneButtonMode.BlinkingGreen;
                case StopQueued: SceneButtonMode.Green;
                case Stopped: SceneButtonMode.Off;
            }
            sceneLaunchDisplay.set(0, track, mode);
        });

        pages.push({arrowDisplay: arrowDisplay, gridWidget: clipLauncher});

        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.StopAllClips, (_:Int) -> {
            if (shift) clipView.returnToArrangement();
            else clipView.stopAllClips();
        }));
    }

    private function setupTrackView(trackView:grig.controller.TrackView):Void
    {
        for (_ in 0...SCENE_BUTTONS[0].length) {
            trackCtrlDisplays.push(new MidiDisplay(TRACK_BUTTONS, TrackButtonMode.Off, 0));
        }
        
        trackView.addTrackStateUpdateCallback((track:Int, state:grig.controller.TrackState) -> {
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

        midiTriggerList.push(new MultiNoteTrigger(TRACK_BUTTONS[0], (idx:Int, _:Int) -> {
            if (!shift) {
                switch trackMode {
                    case ClipStop: trackView.stopTrack(idx);
                    case Solo: trackView.soloTrack(idx);
                    case RecArm: trackView.armTrack(idx);
                    case Mute: trackView.muteTrack(idx);
                    case Select: trackView.selectTrack(idx);
                }
            }
        }));

        for (i in 0...trackView.getNumTracks()) {
            switch trackView.getSendView(i) {
                case Success(send):
                    sends.push(send);
                case Failure(error):
                    host.logMessage('Sends unavailable: ${error.message}');
                    break;
            }
        }

        var knobCCs = [for (i in 0...WIDTH) i + LOWEST_CC];
        ctrlMidiTriggerList.push(new MultiNoteTrigger(knobCCs, (idx:Int, value:Int) -> {
            var valueF:Float = value / 127;
            switch knobMode {
                case Volume: trackView.setVolume(idx, valueF);
                case Pan: trackView.setPan(idx, valueF);
                case Send:
                    if (idx < sends.length) sends[idx].setLevel(0, valueF);
                case Device:
                    if (parameterView != null) parameterView.setValue(idx, valueF);
            }
        }));
    }


    private function setupVirtualKeyboard(hostMidiOut:MidiSender):Void
    {
        var matrixKeyboardDisplay = new MidiDisplay(gridNotes, GridButtonMode.Off, 0);
        var startPitch = grig.pitch.Pitch.fromNote(grig.pitch.PitchClass.D, 7);
        var matrixKeyboard = new grig.controller.display.MatrixKeyboard(matrixKeyboardDisplay, gridDisplayTable, hostMidiOut, startPitch, WIDTH + 5, HEIGHT * 3, 0, HEIGHT);
        matrixKeyboard.display();

        var arrowDisplay = new MidiDisplay(ARROW_BUTTONS, TrackButtonMode.Off, 0);
        connectMovableToArrows(matrixKeyboard, arrowDisplay);
        pages.push({arrowDisplay: arrowDisplay, gridWidget: matrixKeyboard});
    }

    private function movePage(direction:grig.controller.Direction):Void
    {
        if (pages.length == 0) return;

        var page = pages[pageIndex].gridWidget;
        page.move(direction);
    }

    private function setupTriggers()
    {
        // Transport stuff
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Shift, (_:Int) -> {
            shift = true;
        }));

        // Track controls/arrows/knob controls
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Up, (_:Int) -> {
            if (shift) movePage(Up);
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Down, (_:Int) -> {
            if (shift) movePage(Down);
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Left, (_:Int) -> {
            if (shift) movePage(Left);
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Right, (_:Int) -> {
            if (shift) movePage(Right);
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Volume, (_:Int) -> {
            if (shift) knobMode = KnobMode.Volume;
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Pan, (_:Int) -> {
            if (shift) knobMode = KnobMode.Pan;
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Send, (_:Int) -> {
            if (shift) knobMode = KnobMode.Send;
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Device, (_:Int) -> {
            if (shift) knobMode = KnobMode.Device;
        }));

        // Scene controls
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.ClipStop, (_:Int) -> {
            if (shift) trackMode = TrackMode.ClipStop;
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Solo, (_:Int) -> {
            if (shift) trackMode = TrackMode.Solo;
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.RecArm, (_:Int) -> {
            if (shift) trackMode = TrackMode.RecArm;
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Mute, (_:Int) -> {
            if (shift) trackMode = TrackMode.Mute;
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Select, (_:Int) -> {
            if (shift) trackMode = TrackMode.Select;
        }));

        midiTriggerList.push(new GridNoteTrigger(gridNotes, (x:Int, y:Int, _:Int) -> {
            if (pages.length < 1) return;
            pages[pageIndex].gridWidget.pressButton(x, y, shift);
        }));

        offMidiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Shift, (_:Int) -> {
            shift = false;
        }));

        offMidiTriggerList.push(new GridNoteTrigger(gridNotes, (x:Int, y:Int, _:Int) -> {
            if (pages.length < 1) return;
            pages[pageIndex].gridWidget.releaseButton(x, y, shift);
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
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.PlayPause, (_:Int) -> {
            if (shift) transport.tapTempo();
            else transport.play();
        }));
        midiTriggerList.push(new SingleNoteTrigger(ButtonNotes.Record, (_:Int) -> {
            if (shift) transport.stop();
            else transport.record();
        }));
    }

    public function startup(host:Host)
    {
        this.host = host;

        gridNotes = new Array<Array<Int>>();
        for (i in 0...HEIGHT) {
            gridNotes.push([for (j in 0...WIDTH) (HEIGHT - i - 1) * 8 + j]);
        }

        setupTriggers();
        host.getTransport().handle((outcome) -> {
            switch outcome {
                case Success(transport): setupTransport(transport);
                case Failure(error): host.logMessage('Transport unavailable: ${error.message}');
            }
        });
        host.createClipView(WIDTH, HEIGHT, 1).handle((outcome) -> {
            switch outcome {
                case Success(clipView):
                    setupClipView(clipView);
                    setupTrackView(clipView.getTrackView());
                case Failure(error):
                    host.createTrackView(WIDTH).handle((trackOutcome) -> {
                        switch trackOutcome {
                            case Success(trackView): setupTrackView(trackView);
                            case Failure(trackError): host.logMessage('ClipView and TrackView not available:\n\t$error\n\t$trackError');
                        }
                    });
            }
        });
        host.createParameterView(WIDTH).handle((outcome) -> {
            switch outcome {
                case Success(parameterView):
                    this.parameterView = parameterView;
                case Failure(error): host.logMessage('Parameter view unavailable: ${error.message}');
            }
        });
        host.getMidiIn(0).handle((outcome) -> {
            switch outcome {
                case Success(midiIn): midiIn.setCallback(onMidi);
                case Failure(error): host.logMessage('Midi in unavailable: ${error.message}');
            }
        });
        host.getMidiOut(0).handle((outcome) -> {
            switch outcome {
                case Success(_midiOut): midiOut = _midiOut;
                case Failure(error): host.logMessage('Midi out unavailable: ${error.message}');
            }
        });
        host.getHostMidiOut('', 0, 1).handle((outcome) -> {
            switch outcome {
                case Success(hostMidiOut): setupVirtualKeyboard(hostMidiOut);
                case Failure(error): host.logMessage('Host midi out unavailable: ${error.message}');
            }
        });
        setupDisplays();
        // TODO get knob mode from settings
        knobMode = KnobMode.Volume;
        trackMode = TrackMode.ClipStop;
    }

    public function shutdown()
    {
    }

    private function displayArrows():Void
    {
        if (pages.length == 0) {
            emptyArrowDisplay.display(midiScreen);
            return;
        }
        pages[pageIndex].arrowDisplay.display(midiScreen);
    }

    private function displayGrid():Void
    {
        if (pages.length == 0) return;
        pages[pageIndex].gridWidget.midiDisplay.display(midiScreen);
    }

    private function displayTrackCtrlDisplays()
    {
        if (trackCtrlDisplays.length == 0) {
            knobCtrlDisplay.displayClear(midiScreen);
            emptyArrowDisplay.display(midiScreen);
        }
        trackCtrlDisplays[trackMode].display(midiScreen);
    }

    public function flush()
    {
        if (midiOut == null) return;
        if (shift) {
            displayArrows();
            knobCtrlDisplay.display(midiScreen);
            trackModeDisplay.display(midiScreen);
        } else {
            sceneLaunchDisplay.display(midiScreen);
            displayTrackCtrlDisplays();
        }
        displayGrid();
        midiScreen.display(midiOut);
    }
}