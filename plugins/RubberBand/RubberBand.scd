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
//   transients   — transient mode: 0=crisp, 1=mixed, 2=smooth (R2 only, RT)
//   detector     — detector mode: 0=compound, 1=percussive, 2=soft (R2 only, RT)
//   phase        — phase mode: 0=laminar, 1=independent (R2 only, RT)
//   pitchMode    — pitch mode: 0=highSpeed, 1=highQuality, 2=highConsistency (R2 RT, R3 ctor)
//   engine       — engine: 0=Faster/R2, 1=Finer/R3 (constructor only)
//   window       — window size: 0=standard, 1=short, 2=long (constructor only)
//   channelMode  — channel handling: 0=apart, 1=together (constructor only)
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
// Speed slider, pitch slider, loop toggle, formant toggle, advanced options,
// file drop, and play button. Construction-only options (engine, window,
// channelMode) recreate the synth when changed; R2-only RT options
// (transients, detector, phase, pitchMode) update live via .set().

(
var win, dropArea, speedSlider, pitchSlider, speedReadout, pitchReadout;
var playBtn, loopToggle, formantToggle, synth;
var engineMenu, pitchModeMenu, transientsMenu, detectorMenu, phaseMenu;
var windowMenu, channelMenu;
var currentRate = 1.0, currentPitch = 1.0, loopOn = 0, formantOn = 0;
var currentEngine = 0, currentWindow = 0, currentChannelMode = 0;
var currentTransients = 0, currentDetector = 0, currentPhase = 0, currentPitchMode = 0;

// Rebuild the SynthDef with current ctor-only values baked in, then call completionFunc.
// This avoids Function.play's SynthDef caching, which would silently ignore
// changes to engine/window/channelMode.
var loadPlayerDef = { |completionFunc|
	var eng = currentEngine, wnd = currentWindow, chm = currentChannelMode;
	SynthDef(\rb_gui_player, { |bufnum, rate = 1, pitch = 1, loop = 0,
		formant = 0, transients = 0, detector = 0, phase = 0, pitchMode = 0,
		doneAction = 0|
		var sig = RubberBand.ar(1, bufnum,
			rate: rate, pitchShift: pitch, loop: loop,
			formant: formant, transients: transients, detector: detector,
			phase: phase, pitchMode: pitchMode,
			engine: eng, window: wnd, channelMode: chm,
			doneAction: doneAction);
		Out.ar(0, sig.dup);
	}).load(s, completionFunc);
};

var startSynth = {
	if (synth.notNil) { synth.free; synth = nil };
	loadPlayerDef.value({
		{
			synth = Synth(\rb_gui_player, [
				\bufnum, ~buf.bufnum,
				\rate, currentRate, \pitch, currentPitch,
				\loop, loopOn, \formant, formantOn,
				\transients, currentTransients, \detector, currentDetector,
				\phase, currentPhase, \pitchMode, currentPitchMode,
				\doneAction, 2
			]);
		}.defer;
	});
};

var updateControls = {
	if (synth.notNil) {
		synth.set(\rate, currentRate, \pitch, currentPitch,
			\loop, loopOn, \formant, formantOn,
			\transients, currentTransients, \detector, currentDetector,
			\phase, currentPhase, \pitchMode, currentPitchMode);
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
	Rect(200, 200, 540, 380), resizable: false);

win.layout = VLayout(
	// Drop zone + Browse button
	HLayout(
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
		Button().states_([["Browse...", Color.black, Color.grey(0.85)]])
			.fixedWidth_(70)
			.action_({
				var startDir = if (~path.notNil) { PathName(~path).pathOnly } { nil };
				Dialog.openPanel({ |path| loadFile.value(path) }, nil, false, startDir);
			})
	),

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

	// --- Advanced options ---
	StaticText().string_("Advanced Options")
		.align_(\left)
		.font_(Font.default.bold),

	// Construction-only row (changes recreate the synth)
	HLayout(
		StaticText().string_("Engine:").fixedWidth_(50),
		engineMenu = PopUpMenu()
			.items_(["R2 (Faster)", "R3 (Finer)"])
			.value_(0)
			.action_({ |m|
				currentEngine = m.value;
				startSynth.value; // ctor-only: must recreate
			}),
		StaticText().string_("Window:").fixedWidth_(55),
		windowMenu = PopUpMenu()
			.items_(["Standard", "Short", "Long"])
			.value_(0)
			.action_({ |m|
				currentWindow = m.value;
				startSynth.value;
			}),
		StaticText().string_("Channels:").fixedWidth_(60),
		channelMenu = PopUpMenu()
			.items_(["Apart", "Together"])
			.value_(0)
			.action_({ |m|
				currentChannelMode = m.value;
				startSynth.value;
			})
	),

	// Runtime options row (R2 only; on R3 these are ignored at runtime)
	HLayout(
		StaticText().string_("Pitch:").fixedWidth_(38),
		pitchModeMenu = PopUpMenu()
			.items_(["HighSpeed", "HighQuality", "HighConsistency"])
			.value_(0)
			.action_({ |m|
				currentPitchMode = m.value;
				updateControls.value;
			}),
		StaticText().string_("Trans:").fixedWidth_(40),
		transientsMenu = PopUpMenu()
			.items_(["Crisp", "Mixed", "Smooth"])
			.value_(0)
			.action_({ |m|
				currentTransients = m.value;
				updateControls.value;
			})
	),

	HLayout(
		StaticText().string_("Detect:").fixedWidth_(46),
		detectorMenu = PopUpMenu()
			.items_(["Compound", "Percussive", "Soft"])
			.value_(0)
			.action_({ |m|
				currentDetector = m.value;
				updateControls.value;
			}),
		StaticText().string_("Phase:").fixedWidth_(42),
		phaseMenu = PopUpMenu()
			.items_(["Laminar", "Independent"])
			.value_(0)
			.action_({ |m|
				currentPhase = m.value;
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


// ---- Section 13: BPM-synced loop GUI ----
// RubberBandLoop: original BPM, target BPM (40–200), metronome, drop zone,
// plus advanced Rubber Band options. Construction-only options (engine, window,
// channelMode) are baked into the SynthDef on each Play; RT options
// (formant, transients, detector, phase, pitchMode) update live via .set().
// Requires RubberBandLoop.sc to be in your class library.
// If click/loop phase feels slightly off, try:
// loopPlayer.metronomeOffset = 0.03;  // or 0.06, etc., then press Stop and Play again

(
var win, dropArea, origBPMBox, targetSlider, targetReadout;
var metronomeToggle, playBtn, stopBtn;
var engineMenu, pitchModeMenu, transientsMenu, detectorMenu, phaseMenu;
var windowMenu, channelMenu, formantToggle;
var loopPlayer, bpmBuf, bpmPath;
var targetBPM = 120, originalBPM = 120;
var curEngine = 0, curWindow = 0, curChannelMode = 0;
var curFormant = 0, curTransients = 0, curDetector = 0, curPhase = 0, curPitchMode = 0;
// Default browse folder: same as this SCD file, or last-loaded file's folder
var scdDir = thisProcess.nowExecutingPath.notNil.if(
	PathName(thisProcess.nowExecutingPath).pathOnly, nil);

// Rebuild \rbLoop_player SynthDef with current ctor-only values as defaults,
// then call completionFunc when it's ready on the server.
var loadPlayerDef = { |completionFunc|
	var eng = curEngine, wnd = curWindow, chm = curChannelMode;
	SynthDef(\rbLoop_player, { |bufnum, rate = 1, formant = 0,
		transients = 0, detector = 0, phase = 0, pitchMode = 0|
		var sig = RubberBand.ar(1, bufnum, rate: rate, loop: 1,
			formant: formant, transients: transients, detector: detector,
			phase: phase, pitchMode: pitchMode,
			engine: eng, window: wnd, channelMode: chm);
		Out.ar(0, sig.dup);
	}).load(s, completionFunc);
};

var setRTOptions = {
	if (loopPlayer.notNil and: { loopPlayer.synth.notNil }) {
		loopPlayer.synth.set(
			\formant, curFormant, \transients, curTransients,
			\detector, curDetector, \phase, curPhase,
			\pitchMode, curPitchMode);
	};
};

var loadBPMFile = { |path|
	Buffer.read(s, path, action: { |buf|
		{
			if (bpmBuf.notNil) { bpmBuf.free };
			bpmBuf = buf;
			bpmPath = path;
			dropArea.string = "  " ++ path.basename;
			"Loaded: %".format(path.basename).postln;
		}.defer;
	});
};

s.waitForBoot {
	win = Window("BPM-synced loop", Rect(220, 220, 500, 370), resizable: false);
	win.layout = VLayout(
		HLayout(
			StaticText().string_("Drop loop file:").fixedWidth_(90),
			dropArea = DragSink()
				.string_("  Drop an audio file here")
				.align_(\left)
				.minHeight_(28)
				.background_(Color.grey(0.88))
				.canReceiveDragHandler_({ View.currentDrag.isString and: { PathName(View.currentDrag).isFile } })
				.receiveDragHandler_({ |v| loadBPMFile.value(View.currentDrag) }),
			Button().states_([["Browse...", Color.black, Color.grey(0.85)]])
				.fixedWidth_(70)
				.action_({
					var startDir = if (bpmPath.notNil) { PathName(bpmPath).pathOnly } { scdDir };
					Dialog.openPanel({ |path| loadBPMFile.value(path) }, nil, false, startDir);
				})
		),
		HLayout(
			StaticText().string_("Original BPM:").fixedWidth_(90),
			origBPMBox = NumberBox().value_(120).clipLo_(1).clipHi_(300).fixedWidth_(60)
				.action_({ |nb| originalBPM = nb.value })
		),
		HLayout(
			StaticText().string_("Target BPM:").fixedWidth_(90),
			targetReadout = StaticText().string_("120").fixedWidth_(40).align_(\right),
			targetSlider = Slider().orientation_(\horizontal).value_((120 - 40) / 160)
				.maxHeight_(24)
				.action_({ |sl|
					targetBPM = sl.value.linlin(0, 1, 40, 200).round(1);
					targetReadout.string = targetBPM.asString;
					if (loopPlayer.notNil) { loopPlayer.targetBPM_(targetBPM) };
				})
		),

		// --- Advanced options ---
		StaticText().string_("Advanced Options").align_(\left).font_(Font.default.bold),

		// Construction-only (take effect on next Play)
		HLayout(
			StaticText().string_("Engine:").fixedWidth_(50),
			engineMenu = PopUpMenu()
				.items_(["R2 (Faster)", "R3 (Finer)"])
				.value_(0)
				.action_({ |m| curEngine = m.value }),
			StaticText().string_("Window:").fixedWidth_(55),
			windowMenu = PopUpMenu()
				.items_(["Standard", "Short", "Long"])
				.value_(0)
				.action_({ |m| curWindow = m.value }),
			StaticText().string_("Ch:").fixedWidth_(22),
			channelMenu = PopUpMenu()
				.items_(["Apart", "Together"])
				.value_(0)
				.action_({ |m| curChannelMode = m.value })
		),

		// Runtime options (R2 only; update live)
		HLayout(
			formantToggle = Button()
				.states_([
					["Formant: OFF", Color.black, Color.grey(0.8)],
					["Formant: ON",  Color.white, Color(0.65, 0.45, 0.70)]
				])
				.action_({ |btn| curFormant = btn.value; setRTOptions.value }),
			StaticText().string_("Pitch:").fixedWidth_(38),
			pitchModeMenu = PopUpMenu()
				.items_(["HighSpeed", "HighQuality", "HighConsistency"])
				.value_(0)
				.action_({ |m| curPitchMode = m.value; setRTOptions.value })
		),

		HLayout(
			StaticText().string_("Trans:").fixedWidth_(40),
			transientsMenu = PopUpMenu()
				.items_(["Crisp", "Mixed", "Smooth"])
				.value_(0)
				.action_({ |m| curTransients = m.value; setRTOptions.value }),
			StaticText().string_("Detect:").fixedWidth_(46),
			detectorMenu = PopUpMenu()
				.items_(["Compound", "Percussive", "Soft"])
				.value_(0)
				.action_({ |m| curDetector = m.value; setRTOptions.value }),
			StaticText().string_("Phase:").fixedWidth_(42),
			phaseMenu = PopUpMenu()
				.items_(["Laminar", "Independent"])
				.value_(0)
				.action_({ |m| curPhase = m.value; setRTOptions.value })
		),

		HLayout(
			metronomeToggle = Button()
				.states_([
					["Metronome: OFF", Color.black, Color.grey(0.8)],
					["Metronome: ON",  Color.white, Color(0.35, 0.55, 0.75)]
				])
				.action_({ |btn|
					if (loopPlayer.isNil) { "Load a file and press Play first.".postln; ^nil };
					if (btn.value == 1) { loopPlayer.startMetronome } { loopPlayer.stopMetronome };
				}),
			playBtn = Button()
				.states_([["Play", Color.white, Color(0.35, 0.65, 0.40)]])
				.minHeight_(32)
				.action_({
					if (bpmBuf.isNil) { "Load a loop file first.".postln; ^nil };
					if (loopPlayer.notNil) { loopPlayer.stop };
					// Rebuild SynthDef with current ctor-only values, then start
					loadPlayerDef.value({
						{
							loopPlayer = RubberBandLoop.new(bpmBuf, origBPMBox.value, nil);
							loopPlayer.play(targetBPM, metronome: metronomeToggle.value == 1);
							// Apply current RT options to the new synth
							setRTOptions.value;
						}.defer;
					});
				}),
			stopBtn = Button()
				.states_([["Stop", Color.white, Color(0.65, 0.30, 0.30)]])
				.minHeight_(32)
				.action_({
					if (loopPlayer.notNil) { loopPlayer.stop; loopPlayer = nil };
				})
		)
	);
	win.onClose = {
		if (loopPlayer.notNil) { loopPlayer.stop; loopPlayer = nil };
	};
	win.front;

	// Pre-load SynthDefs (chained so both are on the server before "ready" prints)
	loadPlayerDef.value({
		SynthDef(\rbLoop_metronome, { |freq = 1000, amp = 0.3|
			var sig = SinOsc.ar(freq) * EnvGen.ar(Env.perc(0.001, 0.05), doneAction: 2);
			Out.ar(0, sig ! 2 * amp);
		}).load(s, { "BPM GUI: ready.".postln });
	});
};
)


// ---- Section 14: Engine Comparison (R2 vs R3) ----
// engine: 0 = Faster (R2), 1 = Finer (R3)
// R2 is lower-latency; R3 is higher-quality (especially for pitch shifting).
// Both play the same buffer at half speed so you can A/B the quality.

// R2 (Faster engine) — half speed
{ RubberBand.ar(1, ~buf, rate: 0.5, engine: 0).dup }.play;

// R3 (Finer engine) — half speed
{ RubberBand.ar(1, ~buf, rate: 0.5, engine: 1).dup }.play;

// R2 — octave up
{ RubberBand.ar(1, ~buf, pitchShift: 2.0, engine: 0).dup }.play;

// R3 — octave up (listen for cleaner transients & fewer artifacts)
{ RubberBand.ar(1, ~buf, pitchShift: 2.0, engine: 1).dup }.play;

// R2 — extreme slow (10% speed)
{ RubberBand.ar(1, ~buf, rate: 0.1, engine: 0).dup }.play;

// R3 — extreme slow (10% speed, generally smoother)
{ RubberBand.ar(1, ~buf, rate: 0.1, engine: 1).dup }.play;

// Side-by-side: R2 left ear, R3 right ear (half speed)
(
{
	var r2 = RubberBand.ar(1, ~buf, rate: 0.5, engine: 0);
	var r3 = RubberBand.ar(1, ~buf, rate: 0.5, engine: 1);
	[r2, r3];
}.play;
)


// ---- Section 15: Transient Modes ----
// transients: 0 = Crisp, 1 = Mixed, 2 = Smooth  (R2 engine only)
// Best heard on percussive material (drums, plucked strings).
// Crisp preserves attacks; Smooth smears them for pad-like textures.

// Crisp (default) — sharp transients preserved
{ RubberBand.ar(1, ~buf, rate: 0.5, transients: 0, engine: 0).dup }.play;

// Mixed — softer attacks, some transient detail
{ RubberBand.ar(1, ~buf, rate: 0.5, transients: 1, engine: 0).dup }.play;

// Smooth — smeared transients, ambient/pad texture
{ RubberBand.ar(1, ~buf, rate: 0.5, transients: 2, engine: 0).dup }.play;

// Loop with mouse-switchable transient mode (X axis: 0→Crisp, 1→Mixed, 2→Smooth)
(
{
	var mode = MouseX.kr(0, 2).round;
	RubberBand.ar(1, ~buf,
		rate: 0.5,
		loop: 1,
		transients: mode,
		engine: 0
	).dup;
}.play;
)

// Detector comparison (R2 only): Compound / Percussive / Soft
// Affects how the stretcher identifies transients.
// detector: 0 = Compound, 1 = Percussive, 2 = Soft

// Percussive detector — emphasises drum hits
{ RubberBand.ar(1, ~buf, rate: 0.5, detector: 1, engine: 0).dup }.play;

// Soft detector — treats most content as tonal
{ RubberBand.ar(1, ~buf, rate: 0.5, detector: 2, engine: 0).dup }.play;


// ---- Section 16: Cleanup ----

s.freeAll;
~buf.free;
