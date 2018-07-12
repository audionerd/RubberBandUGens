#include <algorithm>

#include "SC_PlugIn.hpp"
#include <rubberband/RubberBandStretcher.h>

using namespace RubberBand;

static InterfaceTable *ft;

struct RubberBandUGen : public SCUnit {
public:
    RubberBandUGen() {
        Print("new RubberBandUGen\n");

        RubberBandStretcher::setDefaultDebugLevel(3);

        rubberband = new RubberBandStretcher(
            // playback sample rate
            sampleRate(),
            // sound file channels
            // hardcoded for now
            1,
            RubberBandStretcher::OptionProcessRealTime | RubberBandStretcher::OptionTransientsCrisp
        );

        rubberband->setMaxProcessSize(bufferSize());

        setupBuffers();

        playheadPos = 0;

        set_calc_function<RubberBandUGen, &RubberBandUGen::next>();
        next(1); // or ClearUnitOutputs ??
    }

    ~RubberBandUGen() {
        if (rubberband != NULL) {
            delete rubberband;
        }

        RTFree(mWorld, stretchInBufL);
        RTFree(mWorld, stretchInBufR);
        RTFree(mWorld, stretchOutBufL);
        RTFree(mWorld, stretchOutBufR);
        // RTFree(mWorld, stretchInBuf);
        // RTFree(mWorld, stretchOutBuf);
    }

private:
    // The GET_BUF macro fills in these two:
    float m_fbufnum;
    SndBuf *m_buf;

    // state variables
    RubberBandStretcher *rubberband = NULL;
    int playheadPos;

    // Input buffers for the RubberBandStretcher
    float *stretchInBufL;
    float *stretchInBufR;
    // float *stretchInBuf;

    // Output buffers for the RubberBandStretcher
    float *stretchOutBufL;
    float *stretchOutBufR;
    // float *stretchOutBuf;


    // calc function
    void next(int inNumSamples) {
        // Note, there is no "unit" variable here,
        // so you can't use a lot of the traditional helper macros.
        // That's why the C++ header offers replacements.

        // ... but I want to use `unit` so I hack it in anyway ... sneaky :)
        RubberBandUGen * unit = this;

        // in and out are methods of SCUnit that replace IN and OUT.
        // ins are const float*, not float*.

        // const float* numChannels = in(0);
        // const float* bufnum = in(1);
        double rate = 1.0 / std::max((double)in(1)[0], 0.000001);

        // via http://doc.sccode.org/Guides/WritingUGens.html
        // “SuperCollider's buffers and busses are global data structures, and access needs
        // to be synchronized. This is done internally by using reader-writer spinlocks.
        // This is done by using the ACQUIRE_, RELEASE_, and LOCK_ macros, which are
        // defined in SC_Unit.h.”
        //
        // The recommended way to retrieve a buffer. Take the first input of this UGen and
        // use it as a buffer number. This dumps a number of variables into the local
        // scope:
        //    - buf - a pointer to the SndBuf instance
        //    - bufData - the raw float data from the buffer
        //    - bufChannels - the number of channels in the buffer
        //    - bufSamples - the number of samples in the buffer
        //    - bufFrames - the number of frames in the buffer
        GET_BUF

        float* output = out(0);

        int _bufferSize = bufferSize();
        int maxProcessSize = bufferSize();
        int channels = 1;

        rubberband->setTimeRatio(rate);

        // While there are fewer than inNumSamples output samples available,
        // feed more input samples into rubberband
        while (rubberband->available() < inNumSamples) {

            // de-interleave into the rubberband input buffers
            int i, j;
            int channels = 1;
            for (i = 0, j = (playheadPos + i) * channels;
                   i < inNumSamples && j < bufSamples;
                   i++, j += channels) {
               stretchInBufL[i] = bufData[j];
               // stretchInBufR[i] = inputSamples[j + 1];
            }
            while (i < maxProcessSize) {
               stretchInBufL[i] = 0;
               // stretchInBufR[i] = 0;
               i++;
            }

            rubberband->process(&stretchInBufL, inNumSamples, false);

            playheadPos += inNumSamples;
        }

        size_t samplesRetrieved = rubberband->retrieve(&stretchOutBufL, inNumSamples);

        // interleave output from rubberband into audio output
        for (int i = 0; i < inNumSamples; i++) {
            output[i] = stretchOutBufL[i];
            // output[i * channels + 1] = stretchOutBufR[i];
        }
    }

    void setupBuffers() {
      RubberBandUGen * unit = this;
      int bufsize = bufferSize();
      int channels = 1; // hardcoded

      stretchInBufL = (float*)RTAlloc(mWorld, bufsize * sizeof(float));
      stretchInBufR = (float*)RTAlloc(mWorld, bufsize * sizeof(float));
      // stretchInBuf = (float*)RTAlloc(mWorld, channels * sizeof(float));
      // stretchInBuf[0] = &(stretchInBufL[0]);
      // stretchInBuf[1] = &(stretchInBufR[0]);

      stretchOutBufL = (float*)RTAlloc(mWorld, bufsize * sizeof(float));
      stretchOutBufR = (float*)RTAlloc(mWorld, bufsize * sizeof(float));
      // stretchOutBuf = (float*)RTAlloc(mWorld, channels * sizeof(float));
      // stretchOutBuf[0] = &(stretchOutBufL[0]);
      // stretchOutBuf[1] = &(stretchOutBufR[0]);

      if (
        stretchInBufL == NULL ||
        stretchInBufR == NULL ||
        // stretchInBuf == NULL ||
        stretchOutBufL == NULL ||
        stretchOutBufR == NULL
        // stretchOutBuf == NULL
      ) {
         SETCALC(ft->fClearUnitOutputs);
         ClearUnitOutputs(this, 1);

         if(mWorld->mVerbosity > -2) {
             Print("Failed to allocate memory for RubberBand ugen.\n");
         }

         return;
      }

      // Fill the buffer with zeros.
      memset(stretchInBufL, 0, bufsize * sizeof(float));
      memset(stretchInBufR, 0, bufsize * sizeof(float));
      memset(stretchOutBufL, 0, bufsize * sizeof(float));
      memset(stretchOutBufR, 0, bufsize * sizeof(float));
    }
};

PluginLoad(RubberBandUGens) {
    ft = inTable;
    // registerUnit takes the place of the Define*Unit functions.
    // It automatically checks for the presence of a destructor function.
    // However, it does not seem to be possible to disable buffer aliasing with the C++ header.
    registerUnit<RubberBandUGen>(ft, "RubberBand");
}
