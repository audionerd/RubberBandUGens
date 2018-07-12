# RubberBand UGen for SuperCollider

RubberBand is a high-quality C++ library for pitch-shifting and time-stretching audio. I want to use it from a plugin in SuperCollider. This code doesn't work yet! But I'm learning!

### Example

    s.boot;

    b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01-44_1.aiff");

    {
      RubberBand.ar(
        numChannels: b.numChannels,
        bufnum: b.bufnum,
        rate: 0.25
      ).dup;
    }.play;

    b.free;

### Reference

RubberBand implementation was mostly just copied from Ben Saylor’s TuneTutor:
https://github.com/brsaylor/TuneTutor-proto/blob/master/src/timestretcher.cpp
