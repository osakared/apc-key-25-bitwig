// Controller for APC Key 25
// Copyright (C) 2014 Osaka Red LLC

loadAPI(1);

host.defineController("Akai", "APC Key 25", "1.0", "65176610-873b-11e4-b4a9-0800200c9a66");
host.defineMidiPorts(1, 0);
host.addDeviceNameBasedDiscoveryPair(["APC Key 25"], ["APC Key 25"]);
host.addDeviceNameBasedDiscoveryPair(["APC Key 25 MIDI 1"], ["APC Key 25 MIDI 1"]);

var LOWEST_CC = 1;
var HIGHEST_CC = 119;

control_midi = {
   93: 'record',
   91: 'play_pause',
   64: 'shift',
   58: 'clip_stop',
   59: 'solo',
   60: 'rec_arm',
   61: 'mute',
   62: 'select',
   57: 'stop_all_clips',
   40: 'up',
   41: 'down',
   42: 'left',
   43: 'right',
   44: 'volume',
   45: 'pan',
   46: 'send',
   47: 'device'

   // Grid
   // 32 33 34 ...
   // 24
   // 16
   // 8
   // 0
}

function init()
{
   host.getMidiInPort(0).setMidiCallback(onMidi);
   generic = host.getMidiInPort(0).createNoteInput("Akai Key 25", "?1????");
   generic.setShouldConsumeEvents(false);

   // Make CCs 1-119 freely mappable
   userControls = host.createUserControlsSection(HIGHEST_CC - LOWEST_CC + 1);

   for(var i=LOWEST_CC; i<=HIGHEST_CC; i++)
   {
      userControls.getControl(i - LOWEST_CC).setLabel("CC" + i);
   }
}

function onMidi(status, data1, data2)
{
   if (isChannelController(status))
   {
      if (data1 >= LOWEST_CC && data1 <= HIGHEST_CC)
      {
         var index = data1 - LOWEST_CC;
         userControls.getControl(index).set(data2, 128);
      }
   }	 
}

function exit()
{
}
