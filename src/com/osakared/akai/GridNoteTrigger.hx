package com.osakared.akai;

class GridNoteTrigger implements MidiTrigger
{
    private var noteMap = new Map<Int, {x:Int, y:Int}>();
    private var triggerEvent:(x:Int, y:Int)->Void;

    public function new(noteNumbers:Array<Array<Int>>, triggerEvent:(x:Int, y:Int)->Void)
    {
        for (x => row in noteNumbers) {
            for (y => number in row) {
                noteMap[number] = {x: x, y: y};
            }
        }
        this.triggerEvent = triggerEvent;
    }

    public function handle(noteNumber:Int):Bool
    {
        if (!noteMap.exists(noteNumber)) return false;
        var coords = noteMap[noteNumber];
        triggerEvent(coords.x, coords.y);
        return true;
    }
}