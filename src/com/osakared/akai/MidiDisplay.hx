package com.osakared.akai;

typedef DisplayState = {
    var midiNote:Int;
    var midiState:Int;
}

class MidiDisplay
{
    private var states = new Array<Array<DisplayState>>();
    private var defaultState:Int;
    private var channel:Int;

    public function new(midiNotes:Array<Array<Int>>, defaultState:Int, channel:Int)
    {
        this.defaultState = defaultState;
        this.channel = channel;
        for (row in midiNotes) {
            var stateRow = new Array<DisplayState>();
            for (note in row) {
                stateRow.push({
                    midiNote: note,
                    midiState: defaultState
                });
            }
            states.push(stateRow);
        }
    }

    public function clear():Void
    {
        for (stateRow in states) {
            for (state in stateRow) {
                state.midiState = defaultState;
            }
        }
    }

    public function set(row:Int, col:Int, state:Int):Void
    {
        states[row][col].midiState = state;
    }

    public function setExclusive(row:Int, col:Int, state:Int):Void
    {
        clear();
        set(row, col, state);
    }

    public function display(screen:MidiScreen):Void
    {
        for (stateRow in states) {
            for (state in stateRow) {
                screen.print(state.midiNote, state.midiState);
            }
        }
    }

    public function displayClear(screen:MidiScreen):Void
    {
        for (stateRow in states) {
            for (state in stateRow) {
                screen.print(state.midiNote, defaultState);
            }
        }
    }
}