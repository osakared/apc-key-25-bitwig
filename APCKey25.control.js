// Copyright (c) 2015, Osaka Red, LLC and Thomas J. Webb
// All rights reserved.

// 2019-Apr-11: Johan Berntsson: shift+sustain to toggle fixed velocity on/off

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

//  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer
//  in the documentation and/or other materials provided with the distribution.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

loadAPI(1);

// This updates allNotPlaying and allNotQueued
function updateSceneNegativeValues(scene, numTracks)
{
	allEmpty = true;
	allNotPlaying = true;
	allNotQueued = true;
	for (i = 0; i < numTracks; ++i)
	{
		clip = scene.clips[i];
		// Doesn't have anything, skip
		if (clip.hasContent) allEmpty = false;
		else continue;
		if (clip.playing) allNotPlaying = false;
		if (clip.queued) allNotQueued = false;
	}

	// Can't be allPlaying or allQueued if allEmpty
	if (allEmpty)
	{
		allNotPlaying = allNotQueued = true;
	}

	scene.allNotQueued = allNotQueued;
	scene.allNotPlaying = allNotPlaying;
}

// This updates the positive values and dispatches
function updateScenePositiveValues(scene, numTracks, numScenes, scenes, isPlayingObservers, isQueuedObservers)
{
	allPlaying = true;
	allQueued = true;
	allEmpty = true;
	for (i = 0; i < numTracks; ++i)
	{
		clip = scene.clips[i];
		// Doesn't have anything, skip
		if (clip.hasContent) allEmpty = false;
		else continue;
		if (!clip.playing) allPlaying = false;
		if (!clip.queued) allQueued = false;
	}

	// Can't be allPlaying or allQueued if allEmpty
	if (allEmpty)
	{
		allPlaying = allQueued = false;
	}

	// Still think you're allPlaying? Not if other tracks aren't stopped
	if (allPlaying)
	{
		for (i = 0; i < numScenes; ++i)
		{
			// Skip if it's me
			if (i == scene.index) continue;
			if (!scenes[i].allNotPlaying)
			{
				allPlaying = false;
				break;
			}
		}
	}

	// Okay, still think you're allQueued?
	if (allQueued)
	{
		for (i = 0; i < numScenes; ++i)
		{
			if (i == scene.index) continue;
			if (!scenes[i].allNotQueued)
			{
				allQueued = false;
				break;
			}
		}
	}

	// Time to update the scene variables and dispatch to listeners as need be
	if (scene.allPlaying != allPlaying)
	{
		for (i = 0; i < isPlayingObservers.length; ++i)
		{
			isPlayingObservers[i](scene.index, allPlaying);
		}
		scene.allPlaying = allPlaying;
	}

	if (scene.allQueued != allQueued)
	{
		for (i = 0; i < isQueuedObservers.length; ++i)
		{
			isQueuedObservers[i](scene.index, allQueued);
		}
		scene.allQueued = allQueued;
	}
}

function updateScenes(scenes, numTracks, numScenes, isPlayingObservers, isQueuedObservers)
{
	for (j = 0; j < numScenes; ++j)
	{
		scene = scenes[j];
		updateSceneNegativeValues(scene, numTracks);
	}

	for (j = 0; j < numScenes; ++j)
	{
		scene = scenes[j];
		updateScenePositiveValues(scene, numTracks, numScenes, scenes, isPlayingObservers, isQueuedObservers);
	}
}

function prepareClip(clip, track, scenes, numTracks, numScenes, isPlayingObservers, isQueuedObservers)
{
	// The listeners are per track but we're interested in scene
	clipLauncher = track.getClipLauncherSlots();

	clip.contentObserver = function(slot, hasContent)
	{
		scene = scenes[slot];
		sub_clip = scene.clips[clip.trackIndex];
		sub_clip.hasContent = hasContent;
		updateScenes(scenes, numTracks, numScenes, isPlayingObservers, isQueuedObservers);
	}
	clipLauncher.addHasContentObserver(clip.contentObserver);

	clip.playingObserver = function(slot, playing)
	{
		scene = scenes[slot];
		sub_clip = scene.clips[clip.trackIndex];
		sub_clip.playing = playing;
		updateScenes(scenes, numTracks, numScenes, isPlayingObservers, isQueuedObservers);
	}
	clipLauncher.addIsPlayingObserver(clip.playingObserver);

	clip.queuedObserver = function(slot, queued)
	{
		scene = scenes[slot];
		sub_clip = scene.clips[clip.trackIndex];
		sub_clip.queued = queued;
		updateScenes(scenes, numTracks, numScenes, isPlayingObservers, isQueuedObservers);
	}
	clipLauncher.addIsQueuedObserver(clip.queuedObserver);
}

function prepareScene(scene, numTracks, scenes, numScenes)
{
	// All four of these indicate that all clips with content are in given state
	// and in the case of the first two, the remainder are the latter two
	scene.allPlaying = false;
	scene.allQueued = false;
	scene.allNotPlaying = true;
	scene.allNotQueued = true;
	scene.clips = [];
}

// You give this function a track bank, it will listen to changes on that track bank
// and add functions to its ClipLauncherScenesOrSlots that register callbacks, which the objects
// here will call, namely addIsPlayingObserver and addIsQueuedObserver
function addSceneStateCallbacks(trackBank, numTracks, numScenes)
{
	// Each scene is an object with some metadata on it and an array of clips
	// I'm basically getting the 2D array Bitwig gives me and flipping it
	scenes = [];

	// Callbacks that have been registered
	isPlayingObservers = [];
	isQueuedObservers = [];

	for (trackIndex = 0; trackIndex < numTracks; ++trackIndex)
	{
		track = trackBank.getTrack(trackIndex);
		for (sceneIndex = 0; sceneIndex < numScenes; ++sceneIndex)
		{
			// The first time through the outer loop, we want to start creating our scene objects
			if (trackIndex == 0)
			{
				scene = scenes[sceneIndex] = {};
				scene.index = sceneIndex;
				prepareScene(scene, numTracks, scenes, numScenes);
			}
			scene = scenes[sceneIndex];
			clip = scene.clips[trackIndex] = {};
			clip.hasContent = false;
			clip.playing = false;
			clip.queued = false;
			clip.trackIndex = trackIndex;

			// Put a listener on the first clip in a given track

			if (sceneIndex == 0)
			{
				prepareClip(clip, track, scenes, numTracks, numScenes, isPlayingObservers, isQueuedObservers);
			}
		}
	}

	// Since we can't just attach this to the ClipLauncherScenesOrSlots object like I'd like to
	// (because of Java's rules, not because of JavaScrtipt's), we'll have to make our own object
	// and return
	fakeClipLauncherScenes = {};

	fakeClipLauncherScenes.addIsPlayingObserver = function(callable)
	{
		isPlayingObservers.push(callable);

		for (i = 0; i < numScenes; ++i)
		{
			scene = scenes[i];
			callable(i, scene.allPlaying);
		}
	}

	fakeClipLauncherScenes.addIsQueuedObserver = function(callable)
	{
		isQueuedObservers.push(callable);

		for (i = 0; i < numScenes; ++i)
		{
			scene = scenes[i];
			callable(i, scene.allQueued);
		}
	}

	return fakeClipLauncherScenes;
}

host.defineController("Akai", "APC Key 25", "1.2", "65176610-873b-11e4-b4a9-0800200c9a66");
host.defineMidiPorts(1, 1);
host.addDeviceNameBasedDiscoveryPair(["APC Key 25"], ["APC Key 25"]);
host.addDeviceNameBasedDiscoveryPair(["APC Key 25 MIDI 1"], ["APC Key 25 MIDI 1"]);

// Midi notes that are used to change behavior, launch clips, etc.
var controlNote =
{
   record :         93,
   playPause :     91,
   shift :          98,
   clipStop :      82,
   solo :           83,
   recArm :        84,
   mute :           85,
   select :         86,
   stopAllClips : 81,
   up :             64,
   down :           65,
   left :           66,
   right :          67,
   volume :         68,
   pan :            69,
   send :           70,
   device :         71

   // Grid
   // 32 33 34 ...
   // 24
   // 16
   // 8
   // 0
}

// Just the dimensions of the grid
var gridWidth = 8;
var gridHeight = 5;

// An array that maps clip indices to appropriate note values track, scene
var gridValues = [];
for (track = 0; track < gridWidth; ++track)
{
   clips = gridValues[track] = []
   for (scene = 0; scene < gridHeight; ++scene)
   {
      clips[scene] = (gridHeight - 1 - scene) * gridWidth + track;
   }
}

// Midi control change messages from the 8 knobs
var lowestCc = 48;
var highestCc = 55;

// Note velocities to use in responses to trigger the grid notes
var gridButtonMode =
{
   off :            0,
   green :          1,
   blinkingGreen : 2,
   red :            3,
   blinkingRed :   4,
   amber :          5,
   blinkingAmber : 6
}

var trackButtonMode =
{
   off :            0,
   red :            1,
   blinkingRed :   2
}

var sceneButtonMode =
{
   off :            0,
   green :          1,
   blinkingGreen : 2
}

// If shift is being held
var shiftOn = false;
// Which function the knobs currently play
var knobMode = controlNote.device;
// What the present function of the track buttons is
var trackMode = controlNote.clipStop;
// The grid of clips with their states and listener functions, corresponding to the grid on the controller
var grid = [];
// Which track is currently selected
var selectedTrackIndex = 0;
// Represents the different arrow keys and if they are active or not
var arrows = [];
// Represents the scene launchers
var sceneLaunchers = [];
// Index of current send being controlled and the [arbitrary] max send to go to
var numSends = 10;
var sendIndex = 0;

// Some global Bitwig objects
var mainTrackBank;

// Global "fake" Bitwig object
var fakeClipLauncherScenes;

// current device
var currentDevice;

// As described to me by ThomasHelzle
var bitwigClipState =
{
   stopped :   0,
   playing :   1,
   recording : 2
}

// Initializes a clip
function initializeClip(clip, sceneIndex, trackIndex)
{
   // Clip attributes
   clip.hasContent = false;
   // Which state the clip is in
   clip.state = bitwigClipState.stopped;
   // What this is queued for depends on the state, above
   clip.queued = false;
   clip.buttonNoteValue = gridValues[trackIndex][sceneIndex]

   clip.display = function()
   {
      if (clip.queued)
      {
         switch (clip.state)
         {
            case bitwigClipState.stopped:
               if (clip.hasContent) sendMidi(144, clip.buttonNoteValue, gridButtonMode.blinkingAmber);
               else clip.clear();
               break;
            case bitwigClipState.playing:
               sendMidi(144, clip.buttonNoteValue, gridButtonMode.blinkingGreen);
               break;
            case bitwigClipState.recording:
               sendMidi(144, clip.buttonNoteValue, gridButtonMode.blinkingRed);
               break;
         }
      }
      else
      {
         switch (clip.state)
         {
            case bitwigClipState.stopped:
               if (clip.hasContent) sendMidi(144, clip.buttonNoteValue, gridButtonMode.amber);
               else clip.clear();
               break;
            case bitwigClipState.playing:
               sendMidi(144, clip.buttonNoteValue, gridButtonMode.green);
               break;
            case bitwigClipState.recording:
               sendMidi(144, clip.buttonNoteValue, gridButtonMode.red);
               break;
         }
      }
   }

   clip.clear = function()
   {
      sendMidi(144, clip.buttonNoteValue, gridButtonMode.off);
   }
}

// Initializes a track
function initializeTrack(track, trackIndex)
{
   track.clips = [];

   // Track attributes
   track.muted = false;
   track.soloed = false;
   track.armed = false;
   track.exists = false;
   track.matrixStopped = true;
   track.matrixQueuedForStop = false;
   track.selected = false;
   track.index = trackIndex;

   // Callbacks for track changes
   // I can probably greatly reduce the lines of code through metaprogramming
   // but I like how clear it is this way
   track.muteCallback = function(muted)
   {
      track.muted = muted
      track.display();
   }

   track.soloCallback = function(soloed)
   {
      track.soloed = soloed;
      track.display();
   }

   track.armedCallback = function(armed)
   {
      track.armed = armed;
      track.display();
   }

   track.existsCallback = function(exists)
   {
      track.exists = exists;
      track.display();
   }

   track.selectedCallback = function(selected)
   {
      if (selected)
      {
         selectedTrackIndex = track.index;
      }
      track.selected = selected;
      track.display();
   }

   track.matrixStoppedCallback = function(matrixStopped)
   {
      track.matrixStopped = matrixStopped;
      track.display();
   }

   track.matrixQueuedForStopCallback = function(matrixQueuedForStop)
   {
      track.matrixQueuedForStop = matrixQueuedForStop;
      track.display();
   }

   // Callbacks to be called by Bitwig but also to be called when putting it back into clip mode
   // (If I ever implement other modes not seen in the Ableton script, wouldn't that be cool?)
   track.hasContentCallback = function(scene, hasContent)
   {
      clip = track.clips[scene];
      clip.hasContent = hasContent;
      clip.display();
   }

   track.playingStateCallback = function(scene, state, queued)
   {
      clip = track.clips[scene];
      clip.state = state;
      clip.queued = queued;
      clip.display();
   }

   track.display = function()
   {
      // In shift mode, the track buttons go into a different function
      if (shiftOn) return;
      // Duh, don't draw anything if the track doesn't even exist
      if (!track.exists)
      {
         track.clear();
         return;
      }
      switch (trackMode)
      {
         case controlNote.clipStop:
            color = trackButtonMode.red;
            if (track.matrixQueuedForStop)
            {
               color = trackButtonMode.blinkingRed;
            }
            else if (track.matrixStopped)
            {
               color = trackButtonMode.off;
            }
            sendMidi(144, controlNote.up + track.index, color);
            break;
         case controlNote.solo:
            sendMidi(144, controlNote.up + track.index, track.soloed ? trackButtonMode.red : trackButtonMode.off);
            break;
         case controlNote.recArm:
            sendMidi(144, controlNote.up + track.index, track.armed ? trackButtonMode.red : trackButtonMode.off);
            break;
         case controlNote.mute:
            // In Ableton, this works differently (lights on for NOT muted) but that seems wrong to me
            sendMidi(144, controlNote.up + track.index, track.muted ? trackButtonMode.red : trackButtonMode.off);
            break;
         case controlNote.select:
            sendMidi(144, controlNote.up + track.index, track.selected ? trackButtonMode.red : trackButtonMode.off);
            break;
      }
   }

   track.clear = function()
   {
      sendMidi(144, controlNote.up + track.index, trackButtonMode.off);
   }

   // Register the track callbacks
   track_object = mainTrackBank.getTrack(trackIndex);
   track_object.getMute().addValueObserver(track.muteCallback);
   track_object.getSolo().addValueObserver(track.soloCallback);
   track_object.getArm().addValueObserver(track.armedCallback);
   track_object.exists().addValueObserver(track.existsCallback);
   track_object.addIsSelectedObserver(track.selectedCallback);
   track_object.getIsMatrixStopped().addValueObserver(track.matrixStoppedCallback);
   track_object.getIsMatrixQueuedForStop().addValueObserver(track.matrixQueuedForStopCallback);

   for (sceneIndex = 0; sceneIndex < gridHeight; ++sceneIndex)
   {
      clip = {}
      initializeClip(clip, sceneIndex, trackIndex);
      track.clips[sceneIndex] = clip;
   }

   // And the callbacks that pertain to clips
   var clipLauncher = track_object.getClipLauncherSlots();
   clipLauncher.addHasContentObserver(track.hasContentCallback);
   clipLauncher.addPlaybackStateObserver(track.playingStateCallback);
}

// Initializes the grid
function initializeGrid()
{
   // In case this somehow gets called multiple times
   grid = [];

   for (trackIndex = 0; trackIndex < gridWidth; ++trackIndex)
   {
      track = grid[trackIndex] = {};
      initializeTrack(track, trackIndex);
   }
}

function initializeSceneLauncher(sceneLauncher)
{
   sceneLauncher.buttonNoteValue = controlNote.clipStop + i;
   sceneLauncher.playing = false;
   sceneLauncher.queued = false;

   sceneLauncher.display = function()
   {
      if (shiftOn) return;
      scene_mode = sceneButtonMode.off;
      if (sceneLauncher.queued) scene_mode = sceneButtonMode.blinkingGreen;
      else if (sceneLauncher.playing) scene_mode = sceneButtonMode.green;
      sendMidi(144, sceneLauncher.buttonNoteValue, scene_mode);
   }

   sceneLauncher.clear = function()
   {
      sendMidi(144, sceneLauncher.buttonNoteValue, sceneButtonMode.off);
   }
}

function initializeSceneLaunchers()
{
   sceneLaunchers = [];

   for (i = 0; i < gridHeight; ++i)
   {
      sceneLauncher = sceneLaunchers[i] = {};
      initializeSceneLauncher(sceneLauncher);
   }

   fakeClipLauncherScenes.addIsPlayingObserver(function(scene, playing)
   {
      sceneLauncher = sceneLaunchers[scene];
      sceneLauncher.playing = playing;
      sceneLauncher.display();
   });

   fakeClipLauncherScenes.addIsQueuedObserver(function(scene, queued)
   {
      sceneLauncher = sceneLaunchers[scene];
      sceneLauncher.queued = queued;
      sceneLauncher.display();
   });
}

function displaySceneLaunchers()
{
   for (i = 0; i < gridHeight; ++i)
   {
      sceneLaunchers[i].display();
   }
}

function clearSceneLaunchers()
{
   for (i = 0; i < gridHeight; ++i)
   {
      sceneLaunchers[i].clear();
   }
}

function initializeArrow(arrow)
{
   arrow.canScroll = false;

   arrow.canScrollCallback = function(canScroll)
   {
      arrow.canScroll = canScroll;
      arrow.display();
   }

   arrow.display = function()
   {
      if (!shiftOn) return;
      sendMidi(144, arrow.buttonNoteValue, arrow.canScroll ? trackButtonMode.red : trackButtonMode.off);
   }

   arrow.clear = function()
   {
      if (!shiftOn) return;
      sendMidi(144, arrow.buttonNoteValue, trackButtonMode.off);
   }
}

// Initializes the arrow objects
function initializeArrows()
{
   arrows = [];

   up = arrows[0] = {};
   up.buttonNoteValue = controlNote.up;

   down = arrows[1] = {};
   down.buttonNoteValue = controlNote.down;

   left = arrows[2] = {};
   left.buttonNoteValue = controlNote.left;

   right = arrows[3] = {};
   right.buttonNoteValue = controlNote.right;

   for (i = 0; i < 4; ++i)
   {
      arrow = arrows[i];
      initializeArrow(arrow);
   }

   mainTrackBank.addCanScrollScenesUpObserver(up.canScrollCallback);
   mainTrackBank.addCanScrollScenesDownObserver(down.canScrollCallback);
   mainTrackBank.addCanScrollTracksUpObserver(left.canScrollCallback);
   mainTrackBank.addCanScrollTracksDownObserver(right.canScrollCallback);

   for (i = 0; i < 4; ++i)
   {
      arrow = arrows[i];
   }
}

function displayGrid(skip_clips)
{
   for (trackIndex = 0; trackIndex < gridWidth; ++trackIndex)
   {
      track = grid[trackIndex];
      track.display();
      if (!skip_clips)
      {
         for (sceneIndex = 0; sceneIndex < gridHeight; ++sceneIndex)
         {
            clip = grid[trackIndex].clips[sceneIndex];
            clip.display();
         }
      }
   }
}

function clearGrid(skip_clips)
{
   for (trackIndex = 0; trackIndex < gridWidth; ++trackIndex)
   {
      track = grid[trackIndex];
      track.clear();
      if (!skip_clips)
      {
         for (sceneIndex = 0; sceneIndex < gridHeight; ++sceneIndex)
         {
            clip = grid[trackIndex].clips[sceneIndex];
            clip.display();
         }
      }
   }
}

function displayArrows()
{
   for (i = 0; i < 4; ++i)
   {
      arrows[i].display();
   }
}

function clearArrows()
{
   for (i = 0; i < 4; ++i)
   {
      arrows[i].clear();
   }
}

// This will only stop the clips found in mainTrackBank. Is that the right behavior?
function stopAllClips()
{
   mainTrackBank.getClipLauncherScenes().stop();
}

var velocitySensitive = false;
var velocityCurveFixed = [];
var velocityCurveDynamic = [];

function init()
{
   host.getMidiInPort(0).setMidiCallback(onMidi);

   // Make sure to initialize the globals before initializing the grid and callbacks
   mainTrackBank = host.createMainTrackBank(gridWidth, numSends, gridHeight);

   currentDevice = host.createEditorCursorDevice(2);
   // Add callbacks to the scene slots object so that we know if a scene is being launched or played
   fakeClipLauncherScenes = addSceneStateCallbacks(mainTrackBank, gridWidth, gridHeight);

   generic = host.getMidiInPort(0).createNoteInput("Akai Key 25", "?1????");
   for(i = 0; i < 128; i++) {
       velocityCurveDynamic.push(i);
       velocityCurveFixed.push(127);
   }
   velocitySensitive = false;
   generic.setVelocityTranslationTable(velocityCurveFixed);
   generic.setShouldConsumeEvents(false);

   transport = host.createTransportSection();

   initializeArrows();
   initializeSceneLaunchers();
   initializeGrid();
   displaySceneLaunchers();
   displayGrid(false);
}

// Light up the mode lights as appropriate for shift mode
function shiftPressed()
{
   shiftOn = true;
   clearGrid(true);
   clearSceneLaunchers();
   displayArrows();
   sendMidi(144, knobMode, trackButtonMode.red);
   sendMidi(144, trackMode, sceneButtonMode.green);
}

// Leaving shift mode, turn off any lights it turned on
function shiftReleased()
{
   clearArrows();
   shiftOn = false;
   sendMidi(144, knobMode, trackButtonMode.off);
   sendMidi(144, trackMode, sceneButtonMode.off);
   displaySceneLaunchers();
   displayGrid(true);
}

// Change the track button mode and, if in shift mode, switch which button is lighted
function changeTrackButtonMode(mode)
{
   // Do nothing if the note is out of range
   if (mode < controlNote.clipStop || mode > controlNote.select) return;
   // Turn off light
   sendMidi(144, trackMode, sceneButtonMode.off);
   trackMode = mode;
   // Turn the right mode back on
   sendMidi(144, trackMode, sceneButtonMode.green);
}

// Like the above function but for knob modes
function changeKnobControlMode(mode)
{
   if (mode < controlNote.volume || mode > controlNote.device) return;
   changed = knobMode != mode;
   if (changed) sendMidi(144, knobMode, trackButtonMode.off);
   // Iterate the send index if we're dealing with send
   if (mode == controlNote.send)
   {
      if (changed) sendIndex = 0;
      else
      {
         sendIndex++;
         if (sendIndex >= numSends) sendIndex = 0;
      }
   }
   knobMode = mode;
   if (changed) sendMidi(144, knobMode, trackButtonMode.red);
}

function onMidi(status, data1, data2)
{
   // printMidi(status, data1, data2);
   if(status == 177 && data1 == 64 && data2 == 127 && shiftOn) {
      // shift + sustain: toggle velocity sensitity
      printMidi(status, data1, data2);
      if(velocitySensitive) {
         velocitySensitive = false;
         generic.setVelocityTranslationTable(velocityCurveFixed);
      } else {
         velocitySensitive = true;
         generic.setVelocityTranslationTable(velocityCurveDynamic);
      }
   }

   // We only care about what happens on channel 0 here since that's where all the interesting stuff is
   if (MIDIChannel(status) != 0) return;

   if (isNoteOn(status))
   {
      if (shiftOn)
      {
         switch (data1)
         {
            case controlNote.up:
               mainTrackBank.scrollScenesUp();
               break;
            case controlNote.down:
               mainTrackBank.scrollScenesDown();
               break;
            case controlNote.left:
               mainTrackBank.scrollTracksUp();
               break;
            case controlNote.right:
               mainTrackBank.scrollTracksDown();
               break;
            // Functionality not in the manual that this script adds:
            // shift+stopAllClips does return to arrangement
            case controlNote.stopAllClips:
               mainTrackBank.getClipLauncherScenes().returnToArrangement();
               break;
            default:
               if (data1 >= controlNote.clipStop && data1 <= controlNote.select)
               {
                  changeTrackButtonMode(data1);
               }
               else if (data1 >= controlNote.volume && data1 <= controlNote.device)
               {
                  changeKnobControlMode(data1);
               }
               break;
         }
      }
      else
      {
         switch (data1)
         {
            case controlNote.playPause:
               transport.togglePlay();
               break;
            case controlNote.record:
               transport.record();
               break;
            case controlNote.shift:
               shiftPressed();
               break;
            case controlNote.stopAllClips:
               stopAllClips();
               break;
            default:
               // From the grid
               if (data1 >= 0 && data1 < 40)
               {
                  trackIndex = data1 % gridWidth;
                  sceneIndex = gridHeight - 1 - Math.floor(data1 / gridWidth);
                  mainTrackBank.getTrack(trackIndex).getClipLauncherSlots().launch(sceneIndex);
               }
               else if (data1 >= controlNote.up && data1 <= controlNote.device)
               {
                  trackIndex = data1 - controlNote.up;
                  switch (trackMode)
                  {
                     case controlNote.clipStop:
                        mainTrackBank.getTrack(trackIndex).stop();
                        break;
                     case controlNote.solo:
                        mainTrackBank.getTrack(trackIndex).getSolo().toggle();
                        break;
                     case controlNote.recArm:
                        mainTrackBank.getTrack(trackIndex).getArm().toggle();
                        break;
                     case controlNote.mute:
                        mainTrackBank.getTrack(trackIndex).getMute().toggle();
                        break;
                     case controlNote.select:
                        mainTrackBank.getTrack(trackIndex).select();
                  }
               }
               else if (data1 >= controlNote.clipStop && data1 <= controlNote.select)
               {
                  sceneIndex = data1 - controlNote.clipStop;
                  mainTrackBank.getClipLauncherScenes().launch(sceneIndex);
               }
               break;
         }
      }
   }
   else if (isNoteOff(status))
   {
      switch (data1)
      {
         case controlNote.shift:
            shiftReleased();
            break;
      }
   }
   else if (isChannelController(status))
   {
      // Make sure it's in the range. Don't see why it wouldn't be
      if (data1 < lowestCc || data1 > highestCc) return;
      trackIndex = data1 - lowestCc;
      track = mainTrackBank.getTrack(trackIndex);

      // Functionality depends on which mode we're in
      switch (knobMode)
      {
         case controlNote.volume:
            track.getVolume().set(data2, 128);
            break;
         case controlNote.pan:
            track.getPan().set(data2, 128);
            break;
         case controlNote.send:
            // It's not certain that this even exists
            send = track.getSend(sendIndex);
            if (send) send.set(data2, 128);
            break;
         case controlNote.device:
            //mainTrackBank.getTrack(selectedTrackIndex).createCursorDevice().getParameter(trackIndex).set(data2, 128);
            currentDevice.getParameter(trackIndex).set(data2, 128);
            break;
      }
   }
}

function exit()
{
   clearGrid(false);
   clearSceneLaunchers();
}
