#include "SC_PlugIn.hpp"

static InterfaceTable *ft;

struct RubberBand : public SCUnit {
public:
    RubberBand() {
        set_calc_function<RubberBand, &RubberBand::next>();
        next(1);
    }

    // for a destructor:
    //
    // ~RubberBand() {
    //
    // }

private:
    // state variables

    // calc function
    void next(int inNumSamples) {
        // Note, there is no "unit" variable here,
        // so you can't use a lot of the traditional helper macros.

        // That's why the C++ header offers replacements.

        // in and out are methods of SCUnit that replace IN and OUT.
        // ins are const float*, not float*.
        const float* rate = in(0);

        float* outbuf = out(0);

        for (int i = 0; i < inNumSamples; i++) {
            outbuf[i] = rate[i];
        }
    }
};

PluginLoad(RubberBandUGens) {
    ft = inTable;
    // registerUnit takes the place of the Define*Unit functions.
    // It automatically checks for the presence of a destructor function.
    // However, it does not seem to be possible to disable buffer aliasing with the C++ header.
    registerUnit<RubberBand>(ft, "RubberBand");
}
