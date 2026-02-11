// =====================================================================
// RubberBand UGen — Example File
// Time-stretching with pitch preservation
// =====================================================================

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


// ---- Section 2: Basic Stretching ----
// Pitch is preserved at all rates.

// Original speed (sanity check)
{ RubberBand.ar(1, ~buf, rate: 1.0).dup }.play;

// Half speed (2x longer)
{ RubberBand.ar(1, ~buf, rate: 0.1).dup }.play;

// 75% speed
{ RubberBand.ar(1, ~buf, rate: 0.75).dup }.play;

// 1.5x speed
{ RubberBand.ar(1, ~buf, rate: 1.5).dup }.play;

// Cmd+. to stop each one before trying the next.


// ---- Section 3: A/B Comparison — RubberBand vs PlayBuf ----
// Listen to the difference: PlayBuf changes pitch, RubberBand does not.

// PlayBuf at half speed — pitch drops an octave
{ PlayBuf.ar(1, ~buf, rate: 0.5, doneAction: 2).dup * 0.5 }.play;

// RubberBand at half speed — pitch stays the same
{ RubberBand.ar(1, ~buf, rate: 0.5).dup * 0.5 }.play;


// ---- Section 4: Interactive GUI with Speed Slider and File Drop ----
// Evaluate this block to open the control window.

(
var win, dropArea, slider, speedReadout, playBtn, synth;
var currentRate = 1.0;

var startSynth = {
	if (synth.notNil) { synth.free; synth = nil };
	synth = {
		RubberBand.ar(1, ~buf.bufnum, \rate.kr(currentRate)).dup;
	}.play;
};

var updateRate = {
	if (synth.notNil) {
		synth.set(\rate, currentRate);
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

win = Window("RubberBand Time Stretch", Rect(200, 200, 480, 160), resizable: false);

win.layout = VLayout(
	// Drop zone
	dropArea = DragSink()
		.string_("  " ++ (~path ? "Drop an audio file here").basename)
		.align_(\left)
		.minHeight_(36)
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
		slider = Slider().orientation_(\horizontal)
			.value_(0.33) // 100% at startup (1.0 mapped from 1%–300%)
			.action_({ |sl|
				currentRate = sl.value.linexp(0, 1, 0.001, 3.0);
				speedReadout.string = (currentRate * 100).round(1).asInteger.asString ++ "%";
				updateRate.value;
			})
	),

	// Play button — frees any existing synth and starts fresh
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


// ---- Section 5: Envelope-Controlled Speed Ramps ----
// Pitch stays locked while playback speed changes over time.
// The default sound file is ~2.4 s, so keep ramps short
// and don't start too fast or the buffer runs out early.

// Linear ramp: normal speed → near-frozen over 4 seconds
{ RubberBand.ar(1, ~buf, Line.kr(1.0, 0.1, 4)).dup }.play;

// Exponential ramp — most of the slowdown happens up front
{ RubberBand.ar(1, ~buf, XLine.kr(1.0, 0.1, 4)).dup }.play;

// Custom curve: abrupt half-speed drop, then a long crawl
(
{
	var rate = EnvGen.kr(Env([1.0, 0.3, 0.05], [1.5, 4], \exp));
	RubberBand.ar(1, ~buf, rate).dup;
}.play;
)


// ---- Section 6: Cleanup ----

s.freeAll;
~buf.free;
