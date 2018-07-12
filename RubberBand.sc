RubberBand : MultiOutUGen {
  *ar { arg numChannels, bufnum=0, rate=1.0;
    ^this.multiNew('audio', numChannels, bufnum, rate);
  }
	init { arg argNumChannels ... theInputs;
		inputs = theInputs;
		^this.initOutputs(argNumChannels, rate);
	}
	argNamesInputsOffset { ^2 }
}