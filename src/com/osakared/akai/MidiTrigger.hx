package com.osakared.akai;

interface MidiTrigger
{
    /**
     * Handles if the note number matches
     * @param message midi message
     * @return Bool whether it was handled or not
     */
    public function handle(message:grig.midi.MidiMessage):Bool;
}