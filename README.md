# RubberBand UGens for SuperCollider

RubberBand is a high-quality C++ library for pitch-shifting and time-stretching audio. This plugin wraps it as a SuperCollider UGen for real-time time-stretching and pitch-shifting of buffer contents.

### Installation

Prebuilt binaries for macOS (universal), Linux, and Windows are available on the [Releases](https://github.com/audionerd/RubberBandUGens/releases) page. Download the zip for your platform, unzip it, and copy the `RubberBand` folder into your SuperCollider Extensions directory, then recompile the class library.

### Building from Source

Requires a SuperCollider source tree for the plugin headers. The build will try to find it automatically (local `supercollider/` checkout, then common system install paths). You can also set it explicitly:

    git submodule update --init --recursive
    mkdir build && cd build
    cmake .. -DSC_PATH=/path/to/supercollider
    make

Copy the resulting `RubberBand.scx`, `RubberBand.sc`, and `RubberBandLoop.sc` to your SuperCollider extensions folder (e.g. `~/Library/Application Support/SuperCollider/Extensions/`), then recompile the class library. See [DEVELOPER.md](DEVELOPER.md) for detailed setup, install commands, and rebuild workflows.

### Quick Example

    s.boot;

    b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01-44_1.aiff");

    // Play at quarter speed — pitch is preserved
    { RubberBand.ar(1, b, rate: 0.25).dup }.play;

    // Pitch up an octave at normal speed
    { RubberBand.ar(1, b, pitchShift: 2.0).dup }.play;

    // Loop with doneAction
    { RubberBand.ar(1, b, rate: 0.5, loop: 1, doneAction: 2).dup }.play;

    b.free;

A more complete example with an interactive GUI (speed slider, pitch slider, loop toggle, formant control, and drag-and-drop file loading) is included in `RubberBand.scd`. There is also a BPM-synced loop GUI demo (`RubberBandLoop` helper class) that lets you load a drum loop, set its original BPM, and play it back at a different target BPM with an optional metronome click.

### Parameters

    RubberBand.ar(numChannels, bufnum, rate, pitchShift, trig, startPos, loop, doneAction, formant)

| Parameter      | Default | Description |
|----------------|---------|-------------|
| `numChannels`  | —       | Number of output channels. |
| `bufnum`       | `0`     | Buffer to play. |
| `rate`         | `1.0`   | Playback speed. `0.5` = half speed (2x longer), `2.0` = double speed. Pitch is preserved. |
| `pitchShift`   | `1.0`   | Pitch scale factor. `2.0` = octave up, `0.5` = octave down. Independent of speed. |
| `trig`         | `1`     | A positive transition (0 → 1) resets the playhead to `startPos`. Defaults to 1 so playback starts immediately. |
| `startPos`     | `0`     | Start position in frames. Used as the reset target when a trigger fires. |
| `loop`         | `0`     | Loop mode. `0` = play once, `1` = loop continuously. |
| `doneAction`   | `0`     | Action when playback finishes (non-looping only). `0` = do nothing, `2` = free the synth. Same codes as `PlayBuf`. |
| `formant`      | `0`     | Formant preservation. `0` = formants shift with pitch, `1` = preserve formants (better for voice/vocals). Can be changed at runtime. |

### Reference

RubberBand implementation was mostly just copied from [Ben Saylor’s TuneTutor](https://github.com/brsaylor/TuneTutor-proto/blob/57d607bc8e9aeaa8a33db6a8abadfcd0466bd474/src/timestretcher.cpp).
