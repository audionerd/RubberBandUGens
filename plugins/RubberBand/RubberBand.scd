// =====================================================================
// RubberBand UGen — Example File
// Time-stretching with pitch preservation
// =====================================================================

// ---- Section 1: Setup and Configuration ----

// Change these two variables to match your own audio file:
~path = Platform.resourceDir +/+ "sounds/a11wlk01-44_1.aiff";
~originalBPM = 120;  // set this to the source file's tempo

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

// Half speed (2x longer)
{ RubberBand.ar(1, ~buf, rate: 0.5).dup }.play;

// 75% speed
{ RubberBand.ar(1, ~buf, rate: 0.75).dup }.play;

// Original speed (sanity check)
{ RubberBand.ar(1, ~buf, rate: 1.0).dup }.play;

// 1.5x speed
{ RubberBand.ar(1, ~buf, rate: 1.5).dup }.play;

// Cmd+. to stop each one before trying the next.


// ---- Section 3: A/B Comparison — RubberBand vs PlayBuf ----
// Listen to the difference: PlayBuf changes pitch, RubberBand does not.

// PlayBuf at half speed — pitch drops an octave
{ PlayBuf.ar(1, ~buf, rate: 0.5, doneAction: 2).dup * 0.5 }.play;

// RubberBand at half speed — pitch stays the same
{ RubberBand.ar(1, ~buf, rate: 0.5).dup * 0.5 }.play;


// ---- Section 4: Interactive GUI with BPM Slider and File Drop ----
// Evaluate this block to open the beatmatch control window.

(
var win, dropArea, bpmLabel, srcBpmBox, slider, bpmReadout, synth;
var originalBPM = ~originalBPM ? 120;
var currentTargetBPM = originalBPM;

var startSynth = {
	synth = {
		var rate = \rate.kr(1.0);
		RubberBand.ar(1, ~buf.bufnum, rate).dup;
	}.play;
};

var updateRate = {
	if (synth.notNil) {
		synth.set(\rate, currentTargetBPM / originalBPM);
	};
};

var loadFile = { |path|
	var oldSynth = synth;
	synth = nil;
	if (oldSynth.notNil) { oldSynth.free };

	Buffer.read(s, path, action: { |newBuf|
		{
			if (~buf.notNil) { ~buf.free };
			~buf = newBuf;
			~path = path;
			dropArea.string = "  " ++ path.basename;
			startSynth.value;
			updateRate.value;
			"Loaded: %".format(path.basename).postln;
		}.defer;
	});
};

// --- Build the window ---

win = Window("RubberBand Beatmatch", Rect(200, 200, 480, 160), resizable: false);

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

	// Source BPM
	HLayout(
		bpmLabel = StaticText().string_("Source BPM:").fixedWidth_(80),
		srcBpmBox = NumberBox()
			.value_(originalBPM)
			.clipLo_(20).clipHi_(300)
			.step_(1).scroll_step_(1)
			.fixedWidth_(60)
			.action_({ |nb|
				originalBPM = nb.value;
				~originalBPM = originalBPM;
				// keep current target BPM, just recalc the rate
				updateRate.value;
			}),
		nil // stretch
	),

	// Target BPM slider
	HLayout(
		StaticText().string_("Target BPM:").fixedWidth_(80),
		bpmReadout = StaticText()
			.string_(currentTargetBPM.round(0.1).asString)
			.fixedWidth_(50)
			.align_(\right),
		slider = Slider().orientation_(\horizontal)
			.value_(0.5) // center = original BPM
			.action_({ |sl|
				var minBPM = originalBPM * 0.5;
				var maxBPM = originalBPM * 1.5;
				currentTargetBPM = sl.value.linlin(0, 1, minBPM, maxBPM).round(0.1);
				bpmReadout.string = currentTargetBPM.asString;
				updateRate.value;
			})
	)
);

// Start playback
startSynth.value;

win.onClose = {
	if (synth.notNil) { synth.free; synth = nil };
};

win.front;
)


// ---- Section 5: Cleanup ----

s.freeAll;
~buf.free;
