package com.osakared.akai;

class GridNoteTrigger implements MidiTrigger
{
    private var noteMap = new Map<Int, {x:Int, y:Int}>();
    private var triggerEvent:(x:Int, y:Int, value:Int)->Void;

    public function new(noteNumbers:Array<Array<Int>>, triggerEvent:(x:Int, y:Int, value:Int)->Void)
    {
        for (x => row in noteNumbers) {
            for (y => number in row) {
                noteMap[number] = {x: x, y: y};
            }
        }
        this.triggerEvent = triggerEvent;
    }

    public function handle(message:grig.midi.MidiMessage):Bool
    {
        if (!noteMap.exists(message.byte2)) return false;
        var coords = noteMap[message.byte2];
        triggerEvent(coords.x, coords.y, message.byte3);
        return true;
    }
}