RubberBand : MultiOutUGen {
	*ar { arg numChannels, bufnum=0, rate=1.0, pitchShift=1.0, trig=1,
		startPos=0, loop=0, doneAction=0, formant=0;
		^this.multiNew('audio', numChannels, bufnum, rate, pitchShift,
			trig, startPos, loop, doneAction, formant);
	}
	init { arg argNumChannels ... theInputs;
		inputs = theInputs;
		^this.initOutputs(argNumChannels, rate);
	}
	argNamesInputsOffset { ^2 }
}
