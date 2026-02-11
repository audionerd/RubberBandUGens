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


// ---- Section 4: Interactive GUI with BPM Slider and File Drop ----
// Evaluate this block to open the beatmatch control window.

(
var win, dropArea, bpmLabel, srcBpmBox, slider, bpmReadout, playBtn, synth;
var originalBPM = ~originalBPM ? 120;
var currentTargetBPM = originalBPM;
var isPlaying = false;

var updatePlayBtn = {
	playBtn.string = if (isPlaying) { "Stop" } { "Play" };
	playBtn.background = if (isPlaying) { Color(0.85, 0.35, 0.35) } { Color(0.35, 0.75, 0.40) };
};

var onSynthEnd = {
	// called when the synth ends for any reason (server-side free, CmdPeriod, etc.)
	{ synth = nil; isPlaying = false; updatePlayBtn.value }.defer;
};

var startSynth = {
	if (synth.notNil) { synth.free; synth = nil };
	synth = {
		var rate = \rate.kr(1.0);
		RubberBand.ar(1, ~buf.bufnum, rate).dup;
	}.play;
	// watch for the synth node ending (e.g. doneAction, server kill)
	NodeWatcher.register(synth);
	synth.onFree({ onSynthEnd.value });
	isPlaying = true;
	updatePlayBtn.value;
};

var stopSynth = {
	if (synth.notNil) { synth.free; synth = nil };
	isPlaying = false;
	updatePlayBtn.value;
};

var togglePlay = {
	if (isPlaying) { stopSynth.value } { startSynth.value; updateRate.value };
};

var updateRate = {
	if (synth.notNil) {
		synth.set(\rate, currentTargetBPM / originalBPM);
	};
};

var loadFile = { |path|
	var wasPlaying = isPlaying;
	stopSynth.value;

	Buffer.read(s, path, action: { |newBuf|
		{
			if (~buf.notNil) { ~buf.free };
			~buf = newBuf;
			~path = path;
			dropArea.string = "  " ++ path.basename;
			if (wasPlaying) { startSynth.value; updateRate.value };
			"Loaded: %".format(path.basename).postln;
		}.defer;
	});
};

// --- Build the window ---

win = Window("RubberBand Beatmatch", Rect(200, 200, 480, 190), resizable: false);

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
				var minBPM = originalBPM * 0.1;
				var maxBPM = originalBPM * 3.0;
				currentTargetBPM = sl.value.linlin(0, 1, minBPM, maxBPM).round(0.1);
				bpmReadout.string = currentTargetBPM.asString;
				updateRate.value;
			})
	),

	// Play / Stop button
	playBtn = Button()
		.minHeight_(36)
		.font_(Font.default.size_(14).bold)
		.action_({ togglePlay.value })
);

updatePlayBtn.value;

win.onClose = {
	stopSynth.value;
};

win.front;
)


// ---- Section 5: Cleanup ----

s.freeAll;
~buf.free;
