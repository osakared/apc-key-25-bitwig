package com.osakared.akai;

interface GridWidget extends grig.controller.Movable
{
    public var midiDisplay(default, null):MidiDisplay;

    /**
     * Gets name for display
     * @return String
     */
    public function getTitle():String;

    /**
     * Triggered when button at position x,y is pressed
     * @param x 
     * @param y 
     * @param fnBtn 
     */
    public function pressButton(row:Int, column:Int, fnBtn:Bool):Void;

    /**
     * Triggered when button at position x,y is depressed
     * @param x 
     * @param y 
     * @param fbBtn 
     */
    public function releaseButton(row:Int, column:Int, fbBtn:Bool):Void;
}