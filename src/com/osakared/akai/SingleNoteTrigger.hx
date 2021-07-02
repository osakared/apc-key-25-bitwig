package com.osakared.akai;

class SingleNoteTrigger implements MidiTrigger
{
    private var noteNumber:Int;
    private var triggerEvent:(value:Int)->Void;

    public function new(noteNumber:Int, triggerEvent:(value:Int)->Void)
    {
        this.noteNumber = noteNumber;
        this.triggerEvent = triggerEvent;
    }

    public function handle(message:grig.midi.MidiMessage):Bool
    {
        if (this.noteNumber == message.byte2) {
            triggerEvent(message.byte3);
            return true;
        }
        return false;
    }
}