package com.osakared.akai;

enum abstract TrackMode(Int) to Int
{
    var ClipStop  =       0;
    var Solo =            1;
    var RecArm =          2;
    var Mute =            3;
    var Select =          4;
}