package com.osakared.akai;

abstract MidiTriggerList(Array<MidiTrigger>)
{
    inline public function new()
    {
        this = new Array<MidiTrigger>();
    }

    public function handle(message:grig.midi.MidiMessage):Bool
    {
        for (midiTrigger in this) {
            midiTrigger.handle(message);
        }
        return false;
    }

    inline public function push(midiTrigger:MidiTrigger):Void
    {
        this.push(midiTrigger);
    }
}