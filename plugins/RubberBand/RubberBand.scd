// =====================================================================
// RubberBand UGen — Example File
// Real-time time-stretching and pitch-shifting with RubberBand
// =====================================================================
//
// Parameters:
//   numChannels  — number of output channels
//   bufnum       — buffer to play
//   rate         — playback speed (1.0 = normal, 0.5 = half, 2.0 = double)
//   pitchShift   — pitch scale (1.0 = no shift, 2.0 = octave up, 0.5 = down)
//   trig         — positive transition resets playhead to startPos
//   startPos     — start position in frames (reset target for trig)
//   loop         — loop mode (0 = off, 1 = on)
//   doneAction   — action when playback ends (0 = none, 2 = free synth)
//   formant      — formant preservation (0 = off, 1 = on; best for vocals)
//
// Cmd+. (Cmd-period) stops all running synths.


// ---- Section 1: Setup and Configuration ----

// Change this to your own audio file:
~path = Platform.resourceDir +/+ "sounds/a11wlk01-44_1.aiff";

// Or pick a file interactively:
// Dialog.openPanel({ |path| ~path = path });

(
s.waitForBoot {
	~buf = Buffer.read(s, ~path, action: { |buf|
		"Loaded: % (% frames, % sec, % ch)".format(
			~path.basename, buf.numFrames,
			(buf.numFrames / buf.sampleRate).round(0.01),
			buf.numChannels
		).postln;
	});
};
)


// ---- Section 2: Basic Time-Stretching ----
// Pitch is preserved at all rates.

// Original speed (sanity check)
{ RubberBand.ar(1, ~buf, rate: 1.0).dup }.play;

// Half speed (2x longer)
{ RubberBand.ar(1, ~buf, rate: 0.5).dup }.play;

// 75% speed
{ RubberBand.ar(1, ~buf, rate: 0.75).dup }.play;

// 1.5x speed
{ RubberBand.ar(1, ~buf, rate: 1.5).dup }.play;

// Very slow — 10% speed
{ RubberBand.ar(1, ~buf, rate: 0.1).dup }.play;

// Mouse scrubbing — move left=slow, right=fast
{ RubberBand.ar(1, ~buf, rate: MouseX.kr(0.1, 2.0, 1)).dup }.play;


// ---- Section 3: Pitch Shifting ----
// Change pitch independently of playback speed.

// Octave up — same speed, pitch doubled
{ RubberBand.ar(1, ~buf, pitchShift: 2.0).dup }.play;

// Octave down — same speed, pitch halved
{ RubberBand.ar(1, ~buf, pitchShift: 0.5).dup }.play;

// Fifth up (~1.5x frequency)
{ RubberBand.ar(1, ~buf, pitchShift: 1.5).dup }.play;

// Slight detune — chorus-like effect
{ RubberBand.ar(1, ~buf, pitchShift: 1.02).dup }.play;

// Mouse-controlled pitch — left=low, right=high
{ RubberBand.ar(1, ~buf, pitchShift: MouseX.kr(0.5, 2.0, 1)).dup }.play;

// Pitch down with formant preservation (better for voice)
{ RubberBand.ar(1, ~buf, pitchShift: 0.7, formant: 1).dup }.play;


// ---- Section 4: Combined Pitch + Time ----
// Independently control speed and pitch for creative effects.

// Slow + pitch up — chipmunk at half speed
{ RubberBand.ar(1, ~buf, rate: 0.5, pitchShift: 1.8).dup }.play;

// Fast + pitch down — bass rumble at double speed
{ RubberBand.ar(1, ~buf, rate: 2.0, pitchShift: 0.5).dup }.play;

// Half-speed, down a fifth — deep slow-motion
{ RubberBand.ar(1, ~buf, rate: 0.5, pitchShift: 0.667).dup }.play;

// Mouse controls both: X=speed, Y=pitch
(
{
	RubberBand.ar(1, ~buf,
		rate: MouseX.kr(0.2, 2.0, 1),
		pitchShift: MouseY.kr(0.5, 2.0, 1)
	).dup;
}.play;
)


// ---- Section 5: A/B Comparison — RubberBand vs PlayBuf ----
// PlayBuf changes pitch with speed; RubberBand does not.

// PlayBuf at half speed — pitch drops an octave
{ PlayBuf.ar(1, ~buf, rate: 0.5, doneAction: 2).dup * 0.5 }.play;

// RubberBand at half speed — pitch stays the same
{ RubberBand.ar(1, ~buf, rate: 0.5, doneAction: 2).dup * 0.5 }.play;

// PlayBuf at double speed — pitch rises an octave
{ PlayBuf.ar(1, ~buf, rate: 2.0, doneAction: 2).dup * 0.5 }.play;

// RubberBand at double speed — pitch stays the same
{ RubberBand.ar(1, ~buf, rate: 2.0, doneAction: 2).dup * 0.5 }.play;


// ---- Section 6: LFO Modulation ----
// Speed changes that would normally cause pitch wobble,
// but RubberBand keeps pitch locked.

// Tape flutter — speed wavers, pitch doesn't
{ RubberBand.ar(1, ~buf, SinOsc.kr(0.5).range(0.7, 1.3)).dup }.play;

// Drunken playback — random speed variation
{ RubberBand.ar(1, ~buf, LFNoise1.kr(2).range(0.5, 1.5)).dup }.play;

// Rhythmic stutter between full and half speed
{ RubberBand.ar(1, ~buf, LFPulse.kr(3).range(0.5, 1.0)).dup }.play;

// Slow pendulum — speed swings between slow and fast
{ RubberBand.ar(1, ~buf, LFTri.kr(0.25).range(0.3, 1.5)).dup }.play;

// Accelerating — starts slow, speeds up (no pitch rise)
{ RubberBand.ar(1, ~buf, XLine.kr(0.2, 1.5, 4)).dup }.play;

// LFO on pitch — vibrato effect
{ RubberBand.ar(1, ~buf, pitchShift: SinOsc.kr(5).range(0.95, 1.05)).dup }.play;

// Slow pitch drift — eerie detuning
{ RubberBand.ar(1, ~buf, pitchShift: LFNoise1.kr(0.3).range(0.8, 1.2)).dup }.play;


// ---- Section 7: Looping ----
// Loop the buffer continuously. Synth stays alive until you stop it.

// Simple loop at normal speed
{ RubberBand.ar(1, ~buf, rate: 1.0, loop: 1).dup }.play;

// Loop at half speed
{ RubberBand.ar(1, ~buf, rate: 0.5, loop: 1).dup }.play;

// Loop with evolving pitch — slow rise over each cycle
(
{
	RubberBand.ar(1, ~buf,
		rate: 0.8,
		pitchShift: LFSaw.kr(0.1).range(0.8, 1.5),
		loop: 1
	).dup;
}.play;
)


// ---- Section 8: Trigger and Start Position ----
// Use trig to restart playback. Combined with startPos,
// you can jump to any point in the buffer.

// Retrigger every 2 seconds — always restarts from the beginning
{ RubberBand.ar(1, ~buf, rate: 1.0, trig: Impulse.kr(0.5)).dup }.play;

// Retrigger from the halfway point
(
{
	RubberBand.ar(1, ~buf,
		rate: 1.0,
		trig: Impulse.kr(0.5),
		startPos: BufFrames.kr(~buf) * 0.5
	).dup;
}.play;
)

// Random start position on each trigger
(
{
	var trig = Impulse.kr(1);
	RubberBand.ar(1, ~buf,
		rate: 0.5,
		trig: trig,
		startPos: TRand.kr(0, BufFrames.kr(~buf), trig)
	).dup;
}.play;
)


// ---- Section 9: Done Actions ----
// doneAction: 2 frees the synth when the buffer finishes
// (only fires in non-loop mode).

// Plays once and frees itself
{ RubberBand.ar(1, ~buf, rate: 0.5, doneAction: 2).dup }.play;

// Compare: with loop on, doneAction never fires
{ RubberBand.ar(1, ~buf, rate: 0.5, loop: 1, doneAction: 2).dup }.play;


// ---- Section 10: Interactive GUI ----
// Speed slider, pitch slider, loop toggle, file drop, and play button.

(
var win, dropArea, speedSlider, pitchSlider, speedReadout, pitchReadout;
var playBtn, loopToggle, formantToggle, synth;
var currentRate = 1.0, currentPitch = 1.0, loopOn = 0, formantOn = 0;

var startSynth = {
	if (synth.notNil) { synth.free; synth = nil };
	synth = {
		RubberBand.ar(1, ~buf.bufnum,
			rate: \rate.kr(currentRate),
			pitchShift: \pitch.kr(currentPitch),
			loop: \loop.kr(loopOn),
			formant: \formant.kr(formantOn),
			doneAction: 2
		).dup;
	}.play;
};

var updateControls = {
	if (synth.notNil) {
		synth.set(\rate, currentRate, \pitch, currentPitch,
			\loop, loopOn, \formant, formantOn);
	};
};

var loadFile = { |path|
	if (synth.notNil) { synth.free; synth = nil };

	Buffer.read(s, path, action: { |newBuf|
		{
			if (~buf.notNil) { ~buf.free };
			~buf = newBuf;
			~path = path;
			dropArea.string = "  " ++ path.basename;
			startSynth.value;
			"Loaded: %".format(path.basename).postln;
		}.defer;
	});
};

// --- Build the window ---

win = Window("RubberBand Time Stretch + Pitch Shift",
	Rect(200, 200, 500, 260), resizable: false);

win.layout = VLayout(
	// Drop zone
	dropArea = DragSink()
		.string_("  " ++ (~path ? "Drop an audio file here").basename)
		.align_(\left)
		.minHeight_(32)
		.background_(Color.grey(0.85))
		.canReceiveDragHandler_({
			View.currentDrag.isString and: { PathName(View.currentDrag).isFile }
		})
		.receiveDragHandler_({ |v|
			loadFile.value(View.currentDrag);
		}),

	// Speed slider (1% to 300%)
	HLayout(
		StaticText().string_("Speed:").fixedWidth_(50),
		speedReadout = StaticText()
			.string_("100%")
			.fixedWidth_(50)
			.align_(\right),
		speedSlider = Slider().orientation_(\horizontal)
			.value_(0.33)
			.action_({ |sl|
				currentRate = sl.value.linexp(0, 1, 0.01, 3.0);
				speedReadout.string = (currentRate * 100).round(1).asInteger.asString ++ "%";
				updateControls.value;
			})
	),

	// Pitch slider (-12 to +12 semitones)
	HLayout(
		StaticText().string_("Pitch:").fixedWidth_(50),
		pitchReadout = StaticText()
			.string_("0 st")
			.fixedWidth_(50)
			.align_(\right),
		pitchSlider = Slider().orientation_(\horizontal)
			.value_(0.5)
			.action_({ |sl|
				var semitones = sl.value.linlin(0, 1, -12, 12);
				currentPitch = 2.pow(semitones / 12);
				pitchReadout.string = semitones.round(0.1).asString ++ " st";
				updateControls.value;
			})
	),

	// Toggles row
	HLayout(
		loopToggle = Button()
			.states_([
				["Loop: OFF", Color.black, Color.grey(0.8)],
				["Loop: ON",  Color.white, Color(0.30, 0.55, 0.75)]
			])
			.action_({ |btn|
				loopOn = btn.value;
				updateControls.value;
			}),
		formantToggle = Button()
			.states_([
				["Formant: OFF", Color.black, Color.grey(0.8)],
				["Formant: ON",  Color.white, Color(0.65, 0.45, 0.70)]
			])
			.action_({ |btn|
				formantOn = btn.value;
				updateControls.value;
			})
	),

	// Play button
	playBtn = Button()
		.states_([["Play", Color.white, Color(0.35, 0.65, 0.40)]])
		.minHeight_(36)
		.font_(Font.default.size_(14).bold)
		.action_({ startSynth.value })
);

win.onClose = {
	if (synth.notNil) { synth.free; synth = nil };
};

win.front;
)


// ---- Section 11: Envelope-Controlled Speed Ramps ----
// Pitch stays locked while playback speed changes over time.

// Linear ramp: normal speed -> near-frozen over 4 seconds
{ RubberBand.ar(1, ~buf, Line.kr(1.0, 0.1, 4), doneAction: 2).dup }.play;

// Exponential ramp — most of the slowdown happens up front
{ RubberBand.ar(1, ~buf, XLine.kr(1.0, 0.1, 4), doneAction: 2).dup }.play;

// Custom curve: abrupt half-speed drop, then a long crawl
(
{
	var rate = EnvGen.kr(Env([1.0, 0.3, 0.05], [1.5, 4], \exp));
	RubberBand.ar(1, ~buf, rate, doneAction: 2).dup;
}.play;
)

// Pitch envelope: octave rise over 3 seconds at normal speed
(
{
	var pitch = XLine.kr(1.0, 2.0, 3);
	RubberBand.ar(1, ~buf, pitchShift: pitch, doneAction: 2).dup;
}.play;
)


// ---- Section 12: Vinyl Stop / Start ----
// Compare RubberBand (pitch stays) with PlayBuf (pitch drops with speed).

// Classic vinyl stop — pitch drops as it slows (PlayBuf)
{ PlayBuf.ar(1, ~buf, XLine.kr(1.0, 0.01, 1.5), doneAction: 2).dup }.play;

// Variation: plays at normal speed for 1 second, then stops
(
{
	var rate = EnvGen.kr(Env([1.0, 1.0, 0.01], [1, 1.5], [0, -6]));
	PlayBuf.ar(1, ~buf, rate, doneAction: 2).dup;
}.play;
)

// Pitch-locked stop — slows down but pitch stays put (RubberBand)
{ RubberBand.ar(1, ~buf, XLine.kr(1.0, 0.1, 1.5), doneAction: 2).dup }.play;

// Classic vinyl start — pitch rises as it spins up (PlayBuf)
{ PlayBuf.ar(1, ~buf, XLine.kr(0.01, 1.0, 1.5), doneAction: 2).dup }.play;

// Pitch-locked start — speeds up but pitch stays put (RubberBand)
{ RubberBand.ar(1, ~buf, XLine.kr(0.1, 1.0, 1.5), doneAction: 2).dup }.play;


// ---- Section 13: Cleanup ----

s.freeAll;
~buf.free;
