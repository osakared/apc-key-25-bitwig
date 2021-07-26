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
    var note:Pitch;
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
    private var startPitch:Pitch;
    private var currentCol:Int = 0;
    private var currentRow:Int = 0;
    private var previousCanMoveStates = new Map<Direction, Bool>();
    private var callbacks = new Array<CanMoveChangedCallback>();

    public function new(midiDisplay:MidiDisplay, displayTable:MidiDisplayTable, midiOut:MidiSender, startPitch:Pitch, width:Int, height:Int, currentCol:Int = 0, currentRow:Int = 0)
    {
        this.midiDisplay = midiDisplay;
        this.displayTable = displayTable;
        this.midiOut = midiOut;
        this.startPitch = startPitch;
        matrix = new Array<Array<MatrixKey>>();
        this.currentCol = currentCol;
        this.currentRow = currentRow;
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
        var rowPitch = startPitch;
        for (i in 0...height) {
            var row = new Array<MatrixKey>();
            var currentPitch:Pitch = rowPitch;
            for (j in 0...width) {
                var state = if (!currentPitch.isValidMidiNote()) {
                    displayTable.offState;
                } else if (currentPitch.note.isWhiteKey()) {
                    displayTable.defaultOnState;
                } else displayTable.altOnState;
                row.push({state: state, note: currentPitch});
                currentPitch += 1;
            }
            matrix.push(row);
            rowPitch -= 5;
        }
    }

    public function display():Void
    {
        if (matrix.length == 0) return;
        var width = Ints.min(matrix[0].length - currentCol, midiDisplay.width);
        var height = Ints.min(matrix.length - currentRow, midiDisplay.height);
        for (row in 0...height) {
            for (col in 0...width) {
                midiDisplay.set(row, col, matrix[row+currentRow][col+currentCol].state);
            }
        }
    }

    private function canMove(direction:Direction):Bool
    {
        if (matrix.length == 0) return false;
        return switch direction {
            case Up: currentRow > 0;
            case Down: currentRow + midiDisplay.height < matrix.length;
            case Left: currentCol > 0;
            case Right: currentCol + midiDisplay.width < matrix[0].length;
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
            case Up: currentRow -= 1;
            case Down: currentRow += 1;
            case Left: currentCol -= 1;
            case Right: currentCol += 1;
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

    public function pressButton(row:Int, col:Int, fnBtn:Bool):Void
    {
        var pitch = matrix[row+currentRow][col+currentCol].note;
        if (pitch.isValidMidiNote()) midiOut.sendMessage(MidiMessage.ofMessageType(MessageType.NoteOn, [pitch.toMidiNote(), 64]));
    }

    public function releaseButton(row:Int, col:Int, fbBtn:Bool):Void
    {
        var pitch = matrix[row+currentRow][col+currentCol].note;
        if (pitch.isValidMidiNote()) midiOut.sendMessage(MidiMessage.ofMessageType(MessageType.NoteOff, [pitch.toMidiNote(), 0]));
    }
}