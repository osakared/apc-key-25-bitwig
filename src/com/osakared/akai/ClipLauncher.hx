package com.osakared.akai;

import grig.controller.ClipView;

class ClipLauncher implements GridWidget
{
    public var midiDisplay(default, null):MidiDisplay;
    private var clipView:ClipView;

    public function new(midiDisplay:MidiDisplay, displayTable:MidiDisplayTable, clipView:ClipView)
    {
        this.midiDisplay = midiDisplay;
        this.clipView = clipView;

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
            midiDisplay.set(scene, track, mode);
        });
    }

    public function getTitle():String
    {
        return 'Clip Launcher';
    }

    public function pressButton(row:Int, column:Int, fnBtn:Bool):Void
    {
        if (fnBtn) clipView.recordClip(column, row); // let's make this configurable!
        else clipView.playClip(column, row);
    }

    public function releaseButton(row:Int, column:Int, fbBtn:Bool):Void
    {
    }

    public function move(direction:grig.controller.Direction):Void
    {
        clipView.move(direction);
    }

    public function addCanMoveChangedCallback(callback:grig.controller.CanMoveChangedCallback):Void
    {
        clipView.addCanMoveChangedCallback(callback);
    }
}