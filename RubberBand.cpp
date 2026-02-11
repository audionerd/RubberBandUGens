#include <algorithm>
#include <cstring>

#include "SC_PlugIn.hpp"
#include <rubberband/RubberBandStretcher.h>

using namespace RubberBand;

static InterfaceTable *ft;

struct RubberBandUGen : public SCUnit {
public:
    RubberBandUGen() {
        Print("new RubberBandUGen\n");

        rubberband = new RubberBandStretcher(
            // playback sample rate
            sampleRate(),
            // sound file channels
            // hardcoded for now
            1,
            RubberBandStretcher::OptionProcessRealTime
            // RubberBandStretcher::OptionProcessRealTime |
            // RubberBandStretcher::OptionThreadingNever |
            // RubberBandStretcher::OptionTransientsCrisp |
            // RubberBandStretcher::OptionChannelsTogether
        );

        rubberband->setMaxProcessSize(maxProcessSize);

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
        // RTFree(mWorld, stretchInBufR);
        RTFree(mWorld, stretchOutBufL);
        // RTFree(mWorld, stretchOutBufR);
        // RTFree(mWorld, stretchInBuf);
        // RTFree(mWorld, stretchOutBuf);
    }

private:
    // The GET_BUF macro fills in these two:
    float m_fbufnum;
    SndBuf *m_buf;

    // state variables
    const int maxProcessSize = 512;
    const double minSpeedRatio = 0.000001;

    RubberBandStretcher *rubberband = NULL;
    int playheadPos;

    // Input buffers for the RubberBandStretcher
    float *stretchInBufL;
    // float *stretchInBufR;
    // float *stretchInBuf;

    // Output buffers for the RubberBandStretcher
    float *stretchOutBufL;
    // float *stretchOutBufR;
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
        double rate = 1.0 / std::max((double)in(1)[0], minSpeedRatio);

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

        int channels = 1;

        rubberband->setTimeRatio(rate);

        // While there are fewer than inNumSamples output samples available,
        // feed more input samples into rubberband
        while (rubberband->available() < inNumSamples) {

            // If we've read past the end of the buffer, stop feeding
            if (playheadPos >= (int)bufFrames) {
                break;
            }

            // de-interleave into the rubberband input buffers
            int i, j;
            int channels = 1;
            for (i = 0, j = playheadPos * channels;
                   i < maxProcessSize && j < (int)bufSamples;
                   i++, j += channels) {
               stretchInBufL[i] = bufData[j];
               // stretchInBufR[i] = inputSamples[j + 1];
            }
            while (i < maxProcessSize) {
               stretchInBufL[i] = 0;
               // stretchInBufR[i] = 0;
               i++;
            }

            rubberband->process(&stretchInBufL, maxProcessSize, false);

            playheadPos += maxProcessSize;
        }

        int avail = rubberband->available();
        size_t toRetrieve = std::min(avail > 0 ? (size_t)avail : 0, (size_t)inNumSamples);
        size_t samplesRetrieved = 0;
        if (toRetrieve > 0) {
            samplesRetrieved = rubberband->retrieve(&stretchOutBufL, toRetrieve);
        }

        // copy output from rubberband into audio output, zero-fill remainder
        for (size_t i = 0; i < samplesRetrieved; i++) {
            output[i] = stretchOutBufL[i];
        }
        for (size_t i = samplesRetrieved; i < (size_t)inNumSamples; i++) {
            output[i] = 0.f;
        }
    }

    void setupBuffers() {
      RubberBandUGen * unit = this;
      int channels = 1; // hardcoded

      stretchInBufL = (float*)RTAlloc(mWorld, maxProcessSize * sizeof(float));
      // stretchInBufR = (float*)RTAlloc(mWorld, maxProcessSize * sizeof(float));
      // stretchInBuf = (float*)RTAlloc(mWorld, channels * sizeof(float));
      // stretchInBuf[0] = &(stretchInBufL[0]);
      // stretchInBuf[1] = &(stretchInBufR[0]);

      stretchOutBufL = (float*)RTAlloc(mWorld, maxProcessSize * sizeof(float));
      // stretchOutBufR = (float*)RTAlloc(mWorld, maxProcessSize * sizeof(float));
      // stretchOutBuf = (float*)RTAlloc(mWorld, channels * sizeof(float));
      // stretchOutBuf[0] = &(stretchOutBufL[0]);
      // stretchOutBuf[1] = &(stretchOutBufR[0]);

      if (
        stretchInBufL == NULL ||
        // stretchInBufR == NULL ||
        // stretchInBuf == NULL ||
        stretchOutBufL == NULL
        // stretchOutBufR == NULL
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
      memset(stretchInBufL, 0, maxProcessSize * sizeof(float));
      // memset(stretchInBufR, 0, maxProcessSize * sizeof(float));
      memset(stretchOutBufL, 0, maxProcessSize * sizeof(float));
      // memset(stretchOutBufR, 0, maxProcessSize * sizeof(float));
    }
};

PluginLoad(RubberBandUGens) {
    ft = inTable;
    // registerUnit takes the place of the Define*Unit functions.
    // It automatically checks for the presence of a destructor function.
    // However, it does not seem to be possible to disable buffer aliasing with the C++ header.
    registerUnit<RubberBandUGen>(ft, "RubberBand");
}
