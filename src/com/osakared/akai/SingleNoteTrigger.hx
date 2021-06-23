package com.osakared.akai;

class SingleNoteTrigger implements MidiTrigger
{
    private var noteNumber:Int;
    private var triggerEvent:()->Void;

    public function new(noteNumber:Int, triggerEvent:()->Void)
    {
        this.noteNumber = noteNumber;
        this.triggerEvent = triggerEvent;
    }

    public function handle(noteNumber:Int):Bool
    {
        if (this.noteNumber == noteNumber) {
            triggerEvent();
            return true;
        }
        return false;
    }
}