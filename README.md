# RubberBand UGens for SuperCollider

RubberBand is a high-quality C++ library for pitch-shifting and time-stretching audio. This plugin wraps it as a SuperCollider UGen for real-time time-stretching of buffer contents.

### Building

Requires a SuperCollider source tree for the plugin headers. The build will try to find it automatically (local `supercollider/` checkout, then common system install paths). You can also set it explicitly:

    git submodule update --init --recursive
    mkdir build && cd build
    cmake .. -DSC_PATH=/path/to/supercollider
    make

Copy the resulting `RubberBand.scx` and `RubberBand.sc` to your SuperCollider extensions folder (e.g. `~/Library/Application Support/SuperCollider/Extensions/`), then recompile the class library. See [DEVELOPER.md](DEVELOPER.md) for detailed setup, install commands, and rebuild workflows.

### Quick Example

    s.boot;

    b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01-44_1.aiff");

    // Play at quarter speed — pitch is preserved
    {
      RubberBand.ar(
        numChannels: 1,
        bufnum: b,
        rate: 0.25
      ).dup;
    }.play;

    b.free;

A more complete example with an interactive BPM slider and drag-and-drop file loading is included in `RubberBand.scd`.

### Reference

RubberBand implementation was mostly just copied from [Ben Saylor’s TuneTutor](https://github.com/brsaylor/TuneTutor-proto/blob/57d607bc8e9aeaa8a33db6a8abadfcd0466bd474/src/timestretcher.cpp).
