package com.osakared.akai;

import grig.controller.CanMoveChangedCallback;
import grig.controller.Direction;
import grig.midi.MessageType;
import grig.midi.MidiMessage;
import grig.midi.MidiSender;
import grig.pitch.Pitch;
import grig.pitch.PitchClass;
import thx.Ints;

using haxe.EnumTools;
using grig.controller.DirectionTools;

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
    private var locationX:Int = 0;
    private var locationY:Int = 0;
    private var previousCanMoveStates = new Map<Direction, Bool>();
    private var callbacks = new Array<CanMoveChangedCallback>();

    public function new(midiDisplay:MidiDisplay, displayTable:MidiDisplayTable, midiOut:MidiSender, width:Int, height:Int)
    {
        this.midiDisplay = midiDisplay;
        this.displayTable = displayTable;
        this.midiOut = midiOut;
        matrix = new Array<Array<MatrixKey>>();
        initializeMatrix(width, height);
        for (i in Direction.createAll()) {
            previousCanMoveStates[i] = canMove(i);
        }
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
        var width = Ints.min(matrix[0].length - locationY, midiDisplay.width);
        var height = Ints.min(matrix.length - locationX, midiDisplay.height);
        for (i in 0...height) {
            for (j in 0...width) {
                midiDisplay.set(i, j, matrix[i+locationY][j+locationX].state);
            }
        }
    }

    private function canMove(direction:Direction):Bool
    {
        if (matrix.length == 0) return false;
        return switch direction {
            case Up: locationY > 0;
            case Down: locationY + midiDisplay.width < matrix[0].length;
            case Left: locationX > 0;
            case Right: locationX + midiDisplay.height < matrix.length;
        }
    }

    private function updateCanMoveState(direction:Direction):Void
    {
        var newCanMoveState = canMove(direction);
        if (newCanMoveState != previousCanMoveStates[direction]) {
            for (callback in callbacks) {
                callback(direction, newCanMoveState);
            }
            previousCanMoveStates[direction] = newCanMoveState;
        }
    }

    public function move(direction:Direction):Void
    {
        if (!canMove(direction)) return;
        switch direction {
            case Up: locationY -= 1;
            case Down: locationY += 1;
            case Left: locationX -= 1;
            case Right: locationX += 1;
        }
        updateCanMoveState(direction);
        updateCanMoveState(direction.opposite());
        display();
    }

    public function addCanMoveChangedCallback(callback:CanMoveChangedCallback):Void
    {
        for (i in Direction.createAll()) {
            callback(i, previousCanMoveStates[i]);
        }
        callbacks.push(callback);
    }

    public function pressButton(x:Int, y:Int, fnBtn:Bool):Void
    {
        midiOut.sendMessage(MidiMessage.ofMessageType(MessageType.NoteOn, [matrix[x+locationY][y+locationX].note, 64]));
    }

    public function releaseButton(x:Int, y:Int, fbBtn:Bool):Void
    {
        midiOut.sendMessage(MidiMessage.ofMessageType(MessageType.NoteOff, [matrix[x+locationY][y+locationX].note, 0]));
    }
}