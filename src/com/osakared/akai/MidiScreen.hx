package com.osakared.akai;

/**
 * Manages keeping track of actual changes to what will be displayed
 */
class MidiScreen
{
    private var displays = new Map<Int, {current:Int, pending:Int}>();

    public function new()
    {
    }

    public function print(display:Int, newState:Int):Void
    {
        if (!displays.exists(display)) {
            displays[display] = {current: -1, pending: newState};
        } else {
            displays[display].pending = newState;
        }
    }

    public function display(midiOut:grig.midi.MidiSender):Void
    {
        for (key in displays.keys()) {
            var val = displays[key];
            if (val.current == val.pending) continue;
            var message = [key, val.pending];
            var midiMessage = grig.midi.MidiMessage.ofMessageType(grig.midi.MessageType.NoteOn, message, 0);
            midiOut.sendMessage(midiMessage);
            val.current = val.pending;
        }
    }
}