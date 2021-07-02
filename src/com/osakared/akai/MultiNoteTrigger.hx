package com.osakared.akai;

class MultiNoteTrigger implements MidiTrigger
{
    private var noteNumbers:Array<Int>;
    private var triggerEvent:(idx:Int, value:Int)->Void;

    public function new(noteNumbers:Array<Int>, triggerEvent:(idx:Int, value:Int)->Void)
    {
        this.noteNumbers = noteNumbers;
        this.triggerEvent = triggerEvent;
    }

    public function handle(message:grig.midi.MidiMessage):Bool
    {
        if (noteNumbers.contains(message.byte2)) {
            triggerEvent(noteNumbers.indexOf(message.byte2), message.byte3);
            return true;
        }
        return false;
    }
}