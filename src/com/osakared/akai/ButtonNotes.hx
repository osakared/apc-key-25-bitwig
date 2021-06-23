package com.osakared.akai;

enum abstract ButtonNotes(Int) to Int
{
    // main transport section buttons
    var PlayPause =       91;
    var Record =          93;
    var Shift =           98;

    // scene buttons
    var ClipStop  =       82;
    var Solo =            83;
    var RecArm =          84;
    var Mute =            85;
    var Select =          86;

    // all by itself
    var StopAllClips =    81;

    // arrow and knob control section
    var Up =              64;
    var Down =            65;
    var Left =            66;
    var Right =           67;
    var Volume =          68;
    var Pan =             69;
    var Send =            70;
    var Device =          71;
}