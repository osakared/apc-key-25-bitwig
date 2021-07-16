package com.osakared.akai;

/**
 * Represents a translation between different concerns and the corresponding midi states
 */
typedef MidiDisplayTable = {
    var defaultOnState:Int;
    var altOnState:Int;
    var offState:Int;
    var playingState:Int;
    var recordingState:Int;
    var stoppedState:Int;
    var playingQueuedState:Int;
    var recordingQueuedState:Int;
    var stopQueuedState:Int;
}