// Copyright (c) 2015, Osaka Red, LLC and Thomas J. Webb
// All rights reserved.

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

// This updates all_not_playing and all_not_queued
function updateSceneNegativeValues(scene, num_tracks)
{
	all_empty = true;
	all_not_playing = true;
	all_not_queued = true;
	for (i = 0; i < num_tracks; ++i)
	{
		clip = scene.clips[i];
		// Doesn't have anything, skip
		if (clip.has_content) all_empty = false;
		else continue;
		if (clip.playing) all_not_playing = false;
		if (clip.queued) all_not_queued = false;
	}

	// Can't be all_playing or all_queued if all_empty
	if (all_empty)
	{
		all_not_playing = all_not_queued = true;
	}

	scene.all_not_queued = all_not_queued;
	scene.all_not_playing = all_not_playing;
}

// This updates the positive values and dispatches 
function updateScenePositiveValues(scene, num_tracks, num_scenes, scenes, is_playing_observers, is_queued_observers)
{
	all_playing = true;
	all_queued = true;
	all_empty = true;
	for (i = 0; i < num_tracks; ++i)
	{
		clip = scene.clips[i];
		// Doesn't have anything, skip
		if (clip.has_content) all_empty = false;
		else continue;
		if (!clip.playing) all_playing = false;
		if (!clip.queued) all_queued = false;
	}

	// Can't be all_playing or all_queued if all_empty
	if (all_empty)
	{
		all_playing = all_queued = false;
	}

	// Still think you're all_playing? Not if other tracks aren't stopped
	if (all_playing)
	{
		for (i = 0; i < num_scenes; ++i)
		{
			// Skip if it's me
			if (i == scene.index) continue;
			if (!scenes[i].all_not_playing)
			{
				all_playing = false;
				break;
			}
		}
	}

	// Okay, still think you're all_queued?
	if (all_queued)
	{
		for (i = 0; i < num_scenes; ++i)
		{
			if (i == scene.index) continue;
			if (!scenes[i].all_not_queued)
			{
				all_queued = false;
				break;
			}
		}
	}

	// Time to update the scene variables and dispatch to listeners as need be
	if (scene.all_playing != all_playing)
	{
		for (i = 0; i < is_playing_observers.length; ++i)
		{
			is_playing_observers[i](scene.index, all_playing);
		}
		scene.all_playing = all_playing;
	}

	if (scene.all_queued != all_queued)
	{
		for (i = 0; i < is_queued_observers.length; ++i)
		{
			is_queued_observers[i](scene.index, all_queued);
		}
		scene.all_queued = all_queued;
	}
}

function updateScenes(scenes, num_tracks, num_scenes, is_playing_observers, is_queued_observers)
{
	for (j = 0; j < num_scenes; ++j)
	{
		scene = scenes[j];
		updateSceneNegativeValues(scene, num_tracks);
	}

	for (j = 0; j < num_scenes; ++j)
	{
		scene = scenes[j];
		updateScenePositiveValues(scene, num_tracks, num_scenes, scenes, is_playing_observers, is_queued_observers);
	}
}

function prepareClip(clip, track, scenes, num_tracks, num_scenes, is_playing_observers, is_queued_observers)
{
	// The listeners are per track but we're interested in scene
	clip_launcher = track.getClipLauncherSlots();

	clip.content_observer = function(slot, has_content)
	{
		scene = scenes[slot];
		sub_clip = scene.clips[clip.track_index];
		sub_clip.has_content = has_content;
		updateScenes(scenes, num_tracks, num_scenes, is_playing_observers, is_queued_observers);
	}
	clip_launcher.addHasContentObserver(clip.content_observer);
	
	clip.playing_observer = function(slot, playing)
	{
		scene = scenes[slot];
		sub_clip = scene.clips[clip.track_index];
		sub_clip.playing = playing;
		updateScenes(scenes, num_tracks, num_scenes, is_playing_observers, is_queued_observers);
	}
	clip_launcher.addIsPlayingObserver(clip.playing_observer);

	clip.queued_observer = function(slot, queued)
	{
		scene = scenes[slot];
		sub_clip = scene.clips[clip.track_index];
		sub_clip.queued = queued;
		updateScenes(scenes, num_tracks, num_scenes, is_playing_observers, is_queued_observers);
	}
	clip_launcher.addIsQueuedObserver(clip.queued_observer);
}

function prepareScene(scene, num_tracks, scenes, num_scenes)
{
	// All four of these indicate that all clips with content are in given state
	// and in the case of the first two, the remainder are the latter two
	scene.all_playing = false;
	scene.all_queued = false;
	scene.all_not_playing = true;
	scene.all_not_queued = true;
	scene.clips = [];
}

// You give this function a track bank, it will listen to changes on that track bank
// and add functions to its ClipLauncherScenesOrSlots that register callbacks, which the objects
// here will call, namely addIsPlayingObserver and addIsQueuedObserver
function addSceneStateCallbacks(track_bank, num_tracks, num_scenes)
{
	// Each scene is an object with some metadata on it and an array of clips
	// I'm basically getting the 2D array Bitwig gives me and flipping it
	scenes = [];

	// Callbacks that have been registered
	is_playing_observers = [];
	is_queued_observers = [];

	for (track_index = 0; track_index < num_tracks; ++track_index)
	{
		track = track_bank.getTrack(track_index);
		for (scene_index = 0; scene_index < num_scenes; ++scene_index)
		{
			// The first time through the outer loop, we want to start creating our scene objects
			if (track_index == 0)
			{
				scene = scenes[scene_index] = {};
				scene.index = scene_index;
				prepareScene(scene, num_tracks, scenes, num_scenes);
			}
			scene = scenes[scene_index];
			clip = scene.clips[track_index] = {};
			clip.has_content = false;
			clip.playing = false;
			clip.queued = false;
			clip.track_index = track_index;

			// Put a listener on the first clip in a given track

			if (scene_index == 0)
			{
				prepareClip(clip, track, scenes, num_tracks, num_scenes, is_playing_observers, is_queued_observers);
			}
		}
	}

	// Since we can't just attach this to the ClipLauncherScenesOrSlots object like I'd like to
	// (because of Java's rules, not because of JavaScrtipt's), we'll have to make our own object
	// and return
	fake_clip_launcher_scenes = {};

	fake_clip_launcher_scenes.addIsPlayingObserver = function(callable)
	{
		is_playing_observers.push(callable);

		for (i = 0; i < num_scenes; ++i)
		{
			scene = scenes[i];
			callable(i, scene.all_playing);
		}
	}

	fake_clip_launcher_scenes.addIsQueuedObserver = function(callable)
	{
		is_queued_observers.push(callable);

		for (i = 0; i < num_scenes; ++i)
		{
			scene = scenes[i];
			callable(i, scene.all_queued);
		}
	}

	return fake_clip_launcher_scenes;
}

host.defineController("Akai", "APC Key 25", "1.0", "65176610-873b-11e4-b4a9-0800200c9a66");
host.defineMidiPorts(1, 1);
host.addDeviceNameBasedDiscoveryPair(["APC Key 25"], ["APC Key 25"]);
host.addDeviceNameBasedDiscoveryPair(["APC Key 25 MIDI 1"], ["APC Key 25 MIDI 1"]);

// Midi notes that are used to change behavior, launch clips, etc.
var control_note =
{
   record :         93,
   play_pause :     91,
   shift :          98,
   clip_stop :      82,
   solo :           83,
   rec_arm :        84,
   mute :           85,
   select :         86,
   stop_all_clips : 81,
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
var grid_width = 8;
var grid_height = 5;

// An array that maps clip indices to appropriate note values track, scene
var grid_values = [];
for (track = 0; track < grid_width; ++track)
{
   clips = grid_values[track] = []
   for (scene = 0; scene < grid_height; ++scene)
   {
      clips[scene] = (grid_height - 1 - scene) * grid_width + track;
   }
}

// Midi control change messages from the 8 knobs
var lowest_cc = 48;
var highest_cc = 55;

// Note velocities to use in responses to trigger the grid notes
var grid_button_mode =
{
   off :            0,
   green :          1,
   blinking_green : 2,
   red :            3,
   blinking_red :   4,
   amber :          5,
   blinking_amber : 6
}

var track_button_mode =
{
   off :            0,
   red :            1,
   blinking_red :   2
}

var scene_button_mode =
{
   off :            0,
   green :          1,
   blinking_green : 2
}

// If shift is being held
var shift_on = false;
// Which function the knobs currently play
var knob_mode = control_note.device;
// What the present function of the track buttons is
var track_mode = control_note.clip_stop;
// The grid of clips with their states and listener functions, corresponding to the grid on the controller
var grid = [];
// Which track is currently selected
var selected_track_index = 0;
// Represents the different arrow keys and if they are active or not
var arrows = [];
// Represents the scene launchers
var scene_launchers = [];
// Index of current send being controlled and the [arbitrary] max send to go to
var num_sends = 10;
var send_index = 0;

// Some global Bitwig objects
var main_track_bank;

// Global "fake" Bitwig object
var fake_clip_launcher_scenes;

// As described to me by ThomasHelzle
var bitwig_clip_state =
{
   stopped :   0,
   playing :   1,
   recording : 2
}

// Initializes a clip
function initializeClip(clip, scene_index, track_index)
{
   // Clip attributes
   clip.has_content = false;
   // Which state the clip is in
   clip.state = bitwig_clip_state.stopped;
   // What this is queued for depends on the state, above
   clip.queued = false;
   clip.button_note_value = grid_values[track_index][scene_index]

   clip.display = function()
   {
      if (clip.queued)
      {
         switch (clip.state)
         {
            case bitwig_clip_state.stopped:
               if (clip.has_content) sendMidi(144, clip.button_note_value, grid_button_mode.blinking_amber);
               else clip.clear();
               break;
            case bitwig_clip_state.playing:
               sendMidi(144, clip.button_note_value, grid_button_mode.blinking_green);
               break;
            case bitwig_clip_state.recording:
               sendMidi(144, clip.button_note_value, grid_button_mode.blinking_red);
               break;
         }
      }
      else
      {
         switch (clip.state)
         {
            case bitwig_clip_state.stopped:
               if (clip.has_content) sendMidi(144, clip.button_note_value, grid_button_mode.amber);
               else clip.clear();
               break;
            case bitwig_clip_state.playing:
               sendMidi(144, clip.button_note_value, grid_button_mode.green);
               break;
            case bitwig_clip_state.recording:
               sendMidi(144, clip.button_note_value, grid_button_mode.red);
               break;
         }
      }
   }

   clip.clear = function()
   {
      sendMidi(144, clip.button_note_value, grid_button_mode.off);
   }
}

// Initializes a track
function initializeTrack(track, track_index)
{
   track.clips = [];

   // Track attributes
   track.muted = false;
   track.soloed = false;
   track.armed = false;
   track.exists = false;
   track.matrix_stopped = true;
   track.matrix_queued_for_stop = false;
   track.selected = false;
   track.index = track_index;

   // Callbacks for track changes
   // I can probably greatly reduce the lines of code through metaprogramming
   // but I like how clear it is this way
   track.mute_callback = function(muted)
   {
      track.muted = muted
      track.display();
   }

   track.solo_callback = function(soloed)
   {
      track.soloed = soloed;
      track.display();
   }

   track.armed_callback = function(armed)
   {
      track.armed = armed;
      track.display();
   }

   track.exists_callback = function(exists)
   {
      track.exists = exists;
      track.display();
   }

   track.selected_callback = function(selected)
   {
      if (selected)
      {
         selected_track_index = track.index;
      }
      track.selected = selected;
      track.display();
   }

   track.matrix_stopped_callback = function(matrix_stopped)
   {
      track.matrix_stopped = matrix_stopped;
      track.display();
   }

   track.matrix_queued_for_stop_callback = function(matrix_queued_for_stop)
   {
      track.matrix_queued_for_stop = matrix_queued_for_stop;
      track.display();
   }

   // Callbacks to be called by Bitwig but also to be called when putting it back into clip mode
   // (If I ever implement other modes not seen in the Ableton script, wouldn't that be cool?)
   track.has_content_callback = function(scene, has_content)
   {
      clip = track.clips[scene];
      clip.has_content = has_content;
      clip.display();
   }

   track.playing_state_callback = function(scene, state, queued)
   {
      clip = track.clips[scene];
      clip.state = state;
      clip.queued = queued;
      clip.display();
   }

   track.display = function()
   {
      // In shift mode, the track buttons go into a different function
      if (shift_on) return;
      // Duh, don't draw anything if the track doesn't even exist
      if (!track.exists)
      {
         track.clear();
         return;
      }
      switch (track_mode)
      {
         case control_note.clip_stop:
            color = track_button_mode.red;
            if (track.matrix_queued_for_stop)
            {
               color = track_button_mode.blinking_red;
            }
            else if (track.matrix_stopped)
            {
               color = track_button_mode.off;
            }
            sendMidi(144, control_note.up + track.index, color);
            break;
         case control_note.solo:
            sendMidi(144, control_note.up + track.index, track.soloed ? track_button_mode.red : track_button_mode.off);
            break;
         case control_note.rec_arm:
            sendMidi(144, control_note.up + track.index, track.armed ? track_button_mode.red : track_button_mode.off);
            break;
         case control_note.mute:
            // In Ableton, this works differently (lights on for NOT muted) but that seems wrong to me
            sendMidi(144, control_note.up + track.index, track.muted ? track_button_mode.red : track_button_mode.off);
            break;
         case control_note.select:
            sendMidi(144, control_note.up + track.index, track.selected ? track_button_mode.red : track_button_mode.off);
            break;
      }
   }

   track.clear = function()
   {
      sendMidi(144, control_note.up + track.index, track_button_mode.off);
   }

   // Register the track callbacks
   track_object = main_track_bank.getTrack(track_index);
   track_object.getMute().addValueObserver(track.mute_callback);
   track_object.getSolo().addValueObserver(track.solo_callback);
   track_object.getArm().addValueObserver(track.armed_callback);
   track_object.exists().addValueObserver(track.exists_callback);
   track_object.addIsSelectedObserver(track.selected_callback);
   track_object.getIsMatrixStopped().addValueObserver(track.matrix_stopped_callback);
   track_object.getIsMatrixQueuedForStop().addValueObserver(track.matrix_queued_for_stop_callback);
   
   for (scene_index = 0; scene_index < grid_height; ++scene_index)
   {
      clip = {}
      initializeClip(clip, scene_index, track_index);
      track.clips[scene_index] = clip;
   }

   // And the callbacks that pertain to clips
   var clip_launcher = track_object.getClipLauncherSlots();
   clip_launcher.addHasContentObserver(track.has_content_callback);
   clip_launcher.addPlaybackStateObserver(track.playing_state_callback);
}

// Initializes the grid
function initializeGrid()
{
   // In case this somehow gets called multiple times
   grid = [];

   for (track_index = 0; track_index < grid_width; ++track_index)
   {
      track = grid[track_index] = {};
      initializeTrack(track, track_index);
   }
}

function initializeSceneLauncher(scene_launcher)
{
   scene_launcher.button_note_value = control_note.clip_stop + i;
   scene_launcher.playing = false;
   scene_launcher.queued = false;

   scene_launcher.display = function()
   {
      if (shift_on) return;
      scene_mode = scene_button_mode.off;
      if (scene_launcher.queued) scene_mode = scene_button_mode.blinking_green;
      else if (scene_launcher.playing) scene_mode = scene_button_mode.green;
      sendMidi(144, scene_launcher.button_note_value, scene_mode);
   }

   scene_launcher.clear = function()
   {
      sendMidi(144, scene_launcher.button_note_value, scene_button_mode.off);
   }
}

function initializeSceneLaunchers()
{
   scene_launchers = [];

   for (i = 0; i < grid_height; ++i)
   {
      scene_launcher = scene_launchers[i] = {};
      initializeSceneLauncher(scene_launcher);
   }

   fake_clip_launcher_scenes.addIsPlayingObserver(function(scene, playing)
   {
      scene_launcher = scene_launchers[scene];
      scene_launcher.playing = playing;
      scene_launcher.display();
   });

   fake_clip_launcher_scenes.addIsQueuedObserver(function(scene, queued)
   {
      scene_launcher = scene_launchers[scene];
      scene_launcher.queued = queued;
      scene_launcher.display();
   });
}

function displaySceneLaunchers()
{
   for (i = 0; i < grid_height; ++i)
   {
      scene_launchers[i].display();
   }
}

function clearSceneLaunchers()
{
   for (i = 0; i < grid_height; ++i)
   {
      scene_launchers[i].clear();
   }
}

function initializeArrow(arrow)
{
   arrow.can_scroll = false;

   arrow.can_scroll_callback = function(can_scroll)
   {
      arrow.can_scroll = can_scroll;
      arrow.display();
   }

   arrow.display = function()
   {
      if (!shift_on) return;
      sendMidi(144, arrow.button_note_value, arrow.can_scroll ? track_button_mode.red : track_button_mode.off);
   }

   arrow.clear = function()
   {
      if (!shift_on) return;
      sendMidi(144, arrow.button_note_value, track_button_mode.off);
   }
}

// Initializes the arrow objects
function initializeArrows()
{
   arrows = [];

   up = arrows[0] = {};
   up.button_note_value = control_note.up;

   down = arrows[1] = {};
   down.button_note_value = control_note.down;

   left = arrows[2] = {};
   left.button_note_value = control_note.left;

   right = arrows[3] = {};
   right.button_note_value = control_note.right;

   for (i = 0; i < 4; ++i)
   {
      arrow = arrows[i];
      initializeArrow(arrow);
   }

   main_track_bank.addCanScrollScenesUpObserver(up.can_scroll_callback);
   main_track_bank.addCanScrollScenesDownObserver(down.can_scroll_callback);
   main_track_bank.addCanScrollTracksUpObserver(left.can_scroll_callback);
   main_track_bank.addCanScrollTracksDownObserver(right.can_scroll_callback);

   for (i = 0; i < 4; ++i)
   {
      arrow = arrows[i];
   }
}

function displayGrid(skip_clips)
{
   for (track_index = 0; track_index < grid_width; ++track_index)
   {
      track = grid[track_index];
      track.display();
      if (!skip_clips)
      {
         for (scene_index = 0; scene_index < grid_height; ++scene_index)
         {
            clip = grid[track_index].clips[scene_index];
            clip.display();
         }
      }
   }
}

function clearGrid(skip_clips)
{
   for (track_index = 0; track_index < grid_width; ++track_index)
   {
      track = grid[track_index];
      track.clear();
      if (!skip_clips)
      {
         for (scene_index = 0; scene_index < grid_height; ++scene_index)
         {
            clip = grid[track_index].clips[scene_index];
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

// This will only stop the clips found in main_track_bank. Is that the right behavior?
function stopAllClips()
{
   main_track_bank.getClipLauncherScenes().stop();
}

function init()
{
   host.getMidiInPort(0).setMidiCallback(onMidi);

   // Make sure to initialize the globals before initializing the grid and callbacks
   main_track_bank = host.createMainTrackBank(grid_width, num_sends, grid_height);
   // Add callbacks to the scene slots object so that we know if a scene is being launched or played
   fake_clip_launcher_scenes = addSceneStateCallbacks(main_track_bank, grid_width, grid_height);

   generic = host.getMidiInPort(0).createNoteInput("Akai Key 25", "?1????");
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
   shift_on = true;
   clearGrid(true);
   clearSceneLaunchers();
   displayArrows();
   sendMidi(144, knob_mode, track_button_mode.red);
   sendMidi(144, track_mode, scene_button_mode.green);
}

// Leaving shift mode, turn off any lights it turned on
function shiftReleased()
{
   clearArrows();
   shift_on = false;
   sendMidi(144, knob_mode, track_button_mode.off);
   sendMidi(144, track_mode, scene_button_mode.off);
   displaySceneLaunchers();
   displayGrid(true);
}

// Change the track button mode and, if in shift mode, switch which button is lighted
function changeTrackButtonMode(mode)
{
   // Do nothing if the note is out of range
   if (mode < control_note.clip_stop || mode > control_note.select) return;
   // Turn off light 
   sendMidi(144, track_mode, scene_button_mode.off);
   track_mode = mode;
   // Turn the right mode back on
   sendMidi(144, track_mode, scene_button_mode.green);
}

// Like the above function but for knob modes
function changeKnobControlMode(mode)
{
   if (mode < control_note.volume || mode > control_note.device) return;
   changed = knob_mode != mode;
   if (changed) sendMidi(144, knob_mode, track_button_mode.off);
   // Iterate the send index if we're dealing with send
   if (mode == control_note.send)
   {
      if (changed) send_index = 0;
      else
      {
         send_index++;
         if (send_index >= num_sends) send_index = 0;
      }
   }
   knob_mode = mode;
   if (changed) sendMidi(144, knob_mode, track_button_mode.red);
}

function onMidi(status, data1, data2)
{
   // printMidi(status, data1, data2);

   // We only care about what happens on channel 0 here since that's where all the interesting stuff is
   if (MIDIChannel(status) != 0) return;

   if (isNoteOn(status))
   {
      if (shift_on)
      {
         switch (data1)
         {
            case control_note.up:
               main_track_bank.scrollScenesUp();
               break;
            case control_note.down:
               main_track_bank.scrollScenesDown();
               break;
            case control_note.left:
               main_track_bank.scrollTracksUp();
               break;
            case control_note.right:
               main_track_bank.scrollTracksDown();
               break;
            // Functionality not in the manual that this script adds:
            // shift+stop_all_clips does return to arrangement
            case control_note.stop_all_clips:
               main_track_bank.getClipLauncherScenes().returnToArrangement();
               break;
            default:
               if (data1 >= control_note.clip_stop && data1 <= control_note.select)
               {
                  changeTrackButtonMode(data1);
               }
               else if (data1 >= control_note.volume && data1 <= control_note.device)
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
            case control_note.play_pause:
               transport.togglePlay();
               break;
            case control_note.record:
               transport.record();
               break;
            case control_note.shift:
               shiftPressed();
               break;
            case control_note.stop_all_clips:
               stopAllClips();
               break;
            default:
               // From the grid
               if (data1 >= 0 && data1 < 40)
               {
                  track_index = data1 % grid_width;
                  scene_index = grid_height - 1 - Math.floor(data1 / grid_width);
                  main_track_bank.getTrack(track_index).getClipLauncherSlots().launch(scene_index);
               }
               else if (data1 >= control_note.up && data1 <= control_note.device)
               {
                  track_index = data1 - control_note.up;
                  switch (track_mode)
                  {
                     case control_note.clip_stop:
                        main_track_bank.getTrack(track_index).stop();
                        break;
                     case control_note.solo:
                        main_track_bank.getTrack(track_index).getSolo().toggle();
                        break;
                     case control_note.rec_arm:
                        main_track_bank.getTrack(track_index).getArm().toggle();
                        break;
                     case control_note.mute:
                        main_track_bank.getTrack(track_index).getMute().toggle();
                        break;
                     case control_note.select:
                        main_track_bank.getTrack(track_index).select();
                  }
               }
               else if (data1 >= control_note.clip_stop && data1 <= control_note.select)
               {
                  scene_index = data1 - control_note.clip_stop;
                  main_track_bank.getClipLauncherScenes().launch(scene_index);
               }
               break;
         }
      }
   }
   else if (isNoteOff(status))
   {
      switch (data1)
      {
         case control_note.shift:
            shiftReleased();
            break;
      }
   }
   else if (isChannelController(status))
   {
      // Make sure it's in the range. Don't see why it wouldn't be
      if (data1 < lowest_cc || data1 > highest_cc) return;
      track_index = data1 - lowest_cc;
      track = main_track_bank.getTrack(track_index);

      // Functionality depends on which mode we're in
      switch (knob_mode)
      {
         case control_note.volume:
            track.getVolume().set(data2, 128);
            break;
         case control_note.pan:
            track.getPan().set(data2, 128);
            break;
         case control_note.send:
            // It's not certain that this even exists
            send = track.getSend(send_index);
            if (send) send.set(data2, 128);
            break;
         case control_note.device:
            main_track_bank.getTrack(selected_track_index).getPrimaryDevice().getParameter(track_index).set(data2, 128);
            break;
      }
   }
}

function exit()
{
   clearGrid(false);
   clearSceneLaunchers();
}
