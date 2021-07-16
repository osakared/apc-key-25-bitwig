package com.osakared.akai;

import thx.Ints;
import grig.midi.MessageType;
import grig.midi.MidiMessage;
import grig.midi.MidiSender;
import grig.pitch.Pitch;
import grig.pitch.PitchClass;

typedef MatrixKey = {
    // How it is displayed
    var state:Int;
    // What note is played when this is pressed
    var note:Int;
}

/**
 * Uses a clip launcher-style interface as a keyboard of sorts
 */
class MatrixKeyboard implements GridWidget
{
    public var midiDisplay(default, null):MidiDisplay;
    private var displayTable:MidiDisplayTable;
    private var matrix:Array<Array<MatrixKey>>;
    private var midiOut:MidiSender;

    public function new(midiDisplay:MidiDisplay, displayTable:MidiDisplayTable, midiOut:MidiSender, width:Int, height:Int)
    {
        this.midiDisplay = midiDisplay;
        this.displayTable = displayTable;
        this.midiOut = midiOut;
        matrix = new Array<Array<MatrixKey>>();
        initializeMatrix(width, height);
        display();
    }

    public function getTitle():String
    {
        return 'Matrix Keyboard';
    }

    private function initializeMatrix(width:Int, height:Int):Void
    {
        var rowPitch = grig.pitch.Pitch.fromNote(PitchClass.Db, 5);
        for (i in 0...height) {
            var row = new Array<MatrixKey>();
            var currentPitch:Pitch = rowPitch;
            for (j in 0...width) {
                var state = if (!currentPitch.isValidMidiNote()) {
                    displayTable.offState;
                } else if (currentPitch.note.isWhiteKey()) {
                    displayTable.defaultOnState;
                } else displayTable.altOnState;
                row.push({state: state, note: currentPitch.toMidiNote()});
                currentPitch += 1;
            }
            matrix.push(row);
            rowPitch -= 5;
        }
    }

    public function display():Void
    {
        if (matrix.length == 0) return;
        var width = Ints.min(matrix[0].length, midiDisplay.width);
        var height = Ints.min(matrix.length, midiDisplay.height);
        for (i in 0...height) {
            for (j in 0...width) {

                midiDisplay.set(i, j, matrix[i][j].state);
            }
        }
    }

    public function move(direction:grig.controller.Direction):Void
    {

    }

    public function addCanMoveChangedCallback(callback:grig.controller.CanMoveChangedCallback):Void
    {

    }

    public function pressButton(x:Int, y:Int, fnBtn:Bool):Void
    {
        midiOut.sendMessage(MidiMessage.ofMessageType(MessageType.NoteOn, [matrix[x][y].note, 64]));
    }

    public function releaseButton(x:Int, y:Int, fbBtn:Bool):Void
    {
        midiOut.sendMessage(MidiMessage.ofMessageType(MessageType.NoteOff, [matrix[x][y].note, 0]));
    }
}