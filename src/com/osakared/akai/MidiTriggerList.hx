package com.osakared.akai;

abstract MidiTriggerList(Array<MidiTrigger>)
{
    inline public function new()
    {
        this = new Array<MidiTrigger>();
    }

    public function handle(noteNumber:Int):Bool
    {
        for (midiTrigger in this) {
            if (midiTrigger.handle(noteNumber)) return true;
        }
        return false;
    }

    inline public function push(midiTrigger:MidiTrigger):Void
    {
        this.push(midiTrigger);
    }
}