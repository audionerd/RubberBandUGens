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

Copy the built plugin and SC class file to the Extensions folder:

    cp build/RubberBand.scx ~/Library/Application\ Support/SuperCollider/Extensions/
    cp plugins/RubberBand/RubberBand.sc ~/Library/Application\ Support/SuperCollider/Extensions/

Then recompile the class library in SuperCollider (Cmd+Shift+L or relaunch).

## Rebuild + Install (one-liner)

    cd build && make -j4 && cp RubberBand.scx ~/Library/Application\ Support/SuperCollider/Extensions/

## Clean rebuild

    rm -rf build && mkdir build && cd build && cmake .. && make -j4
