package com.osakared.akai;

interface MidiTrigger
{
    /**
     * Handles if the note number matches
     * @param noteNumber midi note number
     * @return Bool whether it was handled or not
     */
    public function handle(noteNumber:Int):Bool;
}