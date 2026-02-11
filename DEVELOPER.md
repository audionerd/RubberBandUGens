# Developer Guide

## Prerequisites

- CMake 3.5+
- C++14 compiler (Xcode Command Line Tools on macOS)
- SuperCollider source tree (for plugin headers)

## Setup

Clone with submodules:

    git clone --recursive https://github.com/yourname/RubberBandUGens.git
    cd RubberBandUGens

If you already cloned without `--recursive`:

    git submodule update --init --recursive

If you don't have a SuperCollider source tree, clone one into the project folder:

    git clone --depth 1 https://github.com/supercollider/supercollider.git

## Build

    mkdir -p build && cd build
    cmake ..
    make -j4

If SuperCollider source is not in `./supercollider/`, pass it explicitly:

    cmake .. -DSC_PATH=/path/to/supercollider

## Install

Copy the built plugin and SC class files to the Extensions folder:

    cp build/RubberBand.scx ~/Library/Application\ Support/SuperCollider/Extensions/
    cp plugins/RubberBand/RubberBand.sc ~/Library/Application\ Support/SuperCollider/Extensions/
    cp plugins/RubberBand/RubberBandLoop.sc ~/Library/Application\ Support/SuperCollider/Extensions/

Then recompile the class library in SuperCollider (Cmd+Shift+L or relaunch).

## Rebuild + Install (one-liner)

    cd build && make -j4 && cp RubberBand.scx ~/Library/Application\ Support/SuperCollider/Extensions/

## Clean rebuild

    rm -rf build && mkdir build && cd build && cmake .. && make -j4

## UGen Input Mapping

The RubberBand UGen reads its parameters from a fixed set of inputs. Parameters marked **ctor** are read once at construction and baked into the stretcher options. Parameters marked **RT** can be changed every control block.

| Index | Name           | Default | Timing   | Notes |
|-------|----------------|---------|----------|-------|
| 0     | `bufnum`       | 0       | ctor     | Read by SC's `GET_BUF` macro |
| 1     | `rate`         | 1.0     | RT       | Playback speed (positive) |
| 2     | `pitchShift`   | 1.0     | RT       | Pitch scale factor |
| 3     | `trig`         | 1       | RT       | Positive transition resets playhead |
| 4     | `startPos`     | 0       | RT       | Reset target (frames) |
| 5     | `loop`         | 0       | RT       | 0 = off, 1 = on |
| 6     | `doneAction`   | 0       | RT       | Fires when non-looping playback ends |
| 7     | `formant`      | 0       | RT       | 0 = shifted, 1 = preserved |
| 8     | `transients`   | 0       | RT (R2)  | 0 = crisp, 1 = mixed, 2 = smooth |
| 9     | `detector`     | 0       | RT (R2)  | 0 = compound, 1 = percussive, 2 = soft |
| 10    | `phase`        | 0       | RT (R2)  | 0 = laminar, 1 = independent |
| 11    | `pitchMode`    | 0       | RT (R2) / ctor (R3) | 0 = highSpeed, 1 = highQuality, 2 = highConsistency |
| 12    | `engine`       | 0       | ctor     | 0 = Faster/R2, 1 = Finer/R3 |
| 13    | `window`       | 0       | ctor     | 0 = standard, 1 = short, 2 = long |
| 14    | `channelMode`  | 0       | ctor     | 0 = apart, 1 = together |

**R2-only runtime setters** (`setTransientsOption`, `setDetectorOption`, `setPhaseOption`, `setPitchOption`) are called only when `getEngineVersion() == 2`. On the R3 engine these options are either unsupported or construction-only; changing them at runtime would be a no-op or undefined. Each setter is guarded by a `prev*` member variable so the API is only called when the value actually changes.

**Construction-only inputs** (`engine`, `window`, `channelMode`, and `pitchMode` on R3) are read once in the constructor and included in the `Options` bitmask passed to `RubberBandStretcher`. Changing them after construction has no effect.

## Releasing

Pushing a version tag triggers GitHub Actions to build for macOS (universal binary), Linux, and Windows, and attach the zips to a GitHub Release.

    git tag v1.0
    git push --tags

Monitor progress in the [Actions](https://github.com/audionerd/RubberBandUGens/actions) tab. When complete, the release will appear on the [Releases](https://github.com/audionerd/RubberBandUGens/releases) page with per-platform downloads.
