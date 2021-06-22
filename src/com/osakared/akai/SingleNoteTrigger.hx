package com.osakared.akai;

class SingleNoteTrigger implements MidiTrigger
{
    private var noteNumber:Int;
    private var triggerEvent:()->Void;

    public function new(noteNumber_:Int, triggerEvent_:()->Void)
    {
        noteNumber = noteNumber_;
        triggerEvent = triggerEvent_;
    }

    public function handle(noteNumber_:Int):Bool
    {
        if (noteNumber == noteNumber_) {
            triggerEvent();
            return true;
        }
        return false;
    }
}