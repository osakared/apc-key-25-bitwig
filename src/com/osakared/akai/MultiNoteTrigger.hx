package com.osakared.akai;

class MultiNoteTrigger implements MidiTrigger
{
    private var noteNumbers:Array<Int>;
    private var triggerEvent:(idx:Int)->Void;

    public function new(noteNumbers:Array<Int>, triggerEvent:(idx:Int)->Void)
    {
        this.noteNumbers = noteNumbers;
        this.triggerEvent = triggerEvent;
    }

    public function handle(noteNumber:Int):Bool
    {
        if (noteNumbers.contains(noteNumber)) {
            triggerEvent(noteNumbers.indexOf(noteNumber));
            return true;
        }
        return false;
    }
}