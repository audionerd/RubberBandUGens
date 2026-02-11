// RubberBandLoop — BPM-synced looped playback with optional metronome
// Uses RubberBand UGen with rate = targetBPM / originalBPM and loop: 1.
// Both the loop synth and metronome are scheduled on the same TempoClock
// for proper synchronization via server latency compensation.

RubberBandLoop {
	var <buffer, <originalBPM, <numBeats;
	var <clock, <synth, <metronomeRoutine;
	var <targetBPM;
	var <server;
	var <>metronomeOffset; // seconds; compensates for RubberBand UGen startup latency

	*new { arg buffer, originalBPM, numBeats;
		^super.newCopyArgs(buffer, originalBPM, numBeats).init;
	}

	init {
		if (numBeats.isNil and: buffer.notNil) {
			numBeats = (buffer.duration * originalBPM / 60).round(1);
		};
		targetBPM = originalBPM;
		server = buffer.server ?? { Server.default };
		metronomeOffset = 0.05; // 50ms default — tune to taste
	}

	rate { arg bpm;
		var bufRate, srvRate;
		bufRate = buffer.notNil.if({ buffer.sampleRate }, { 0 });
		srvRate = server.notNil.if({ server.sampleRate }, { 0 });
		// Match PlayBuf semantics: compensate when buffer SR != server SR.
		// This keeps loop tempo correct in real time for files like 48k on 44.1k server.
		^((bpm / originalBPM) * ((bufRate > 0 and: { srvRate > 0 }).if({ bufRate / srvRate }, { 1 })));
	}

	play { arg bpm, metronome = false;
		var initRate;
		if (buffer.isNil) { "RubberBandLoop: no buffer.".postln; ^this };
		this.stop;
		targetBPM = bpm ? originalBPM;
		initRate = this.rate(targetBPM);
		this.ensureSynthDefs;
		clock = TempoClock.new(targetBPM / 60);
		// Schedule synth + metronome on the clock so they share
		// the same s.latency-compensated timing base
		Routine({
			synth = Synth(\rbLoop_player, [\bufnum, buffer.bufnum, \rate, initRate], server);
			if (metronome) { this.startMetronome };
		}).play(clock);
		^this;
	}

	targetBPM_ { arg bpm;
		targetBPM = bpm;
		if (clock.notNil) { clock.tempo = bpm / 60 };
		if (synth.notNil) { synth.set(\rate, this.rate(bpm)) };
	}

	startMetronome {
		this.stopMetronome;
		if (clock.isNil) { "RubberBandLoop: start play first.".postln; ^this };
		this.ensureSynthDefs;
		metronomeRoutine = Routine({
			var beat = 0;
			// Compensate for RubberBand stretcher startup latency
			if (metronomeOffset > 0) {
				(metronomeOffset * clock.tempo).wait; // convert seconds → beats
			};
			loop {
				Synth(\rbLoop_metronome, [
					\freq, if (beat % 4 == 0, 1500, 1000),
					\amp, if (beat % 4 == 0, 0.5, 0.25)
				], server);
				beat = beat + 1;
				1.wait;
			}
		}).play(clock);
		^this;
	}

	stopMetronome {
		if (metronomeRoutine.notNil) {
			metronomeRoutine.stop;
			metronomeRoutine = nil;
		};
		^this;
	}

	stop {
		this.stopMetronome;
		if (synth.notNil) { synth.free; synth = nil };
		if (clock.notNil) { clock.stop; clock = nil };
		^this;
	}

	*ensureSynthDefs {
		if (SynthDescLib.at(\rbLoop_player).isNil) {
			SynthDef(\rbLoop_player, { |bufnum, rate = 1|
				var sig = RubberBand.ar(1, bufnum, rate: rate, loop: 1);
				Out.ar(0, sig.dup);
			}).add;
		};
		if (SynthDescLib.at(\rbLoop_metronome).isNil) {
			SynthDef(\rbLoop_metronome, { |freq = 1000, amp = 0.3|
				var sig = SinOsc.ar(freq) * EnvGen.ar(Env.perc(0.001, 0.05), doneAction: 2);
				Out.ar(0, sig ! 2 * amp);
			}).add;
		};
	}

	ensureSynthDefs {
		this.class.ensureSynthDefs;
	}
}
