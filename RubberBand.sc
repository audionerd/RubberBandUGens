RubberBand : UGen {
    *ar { arg rate;
        ^this.multiNew('audio', rate);
    }
}
