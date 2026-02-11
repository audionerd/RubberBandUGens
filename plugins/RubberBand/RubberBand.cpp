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

        numChannels = (int)numOutputs();

        rubberband = new RubberBandStretcher(
            sampleRate(),
            numChannels,
            RubberBandStretcher::OptionProcessRealTime |
            RubberBandStretcher::OptionThreadingNever
        );

        // Set initial time ratio before querying start pad/delay
        double rate = std::max((double)in(1)[0], minSpeedRatio);
        rubberband->setTimeRatio(1.0 / rate);

        setupBuffers();

        // Prime the stretcher with silence to handle start delay.
        // Feed in chunks of maxProcessSize to stay within the API contract.
        size_t startPad = rubberband->getPreferredStartPad();
        if (startPad > 0) {
            // Reuse stretchInBuf (already zeroed) as silent input
            size_t remaining = startPad;
            while (remaining > 0) {
                size_t chunk = std::min(remaining, (size_t)maxProcessSize);
                rubberband->process((const float *const *)stretchInBuf, chunk, false);
                remaining -= chunk;
            }
        }

        startDelay = rubberband->getStartDelay();
        samplesOutput = 0;
        playheadPos = 0;

        set_calc_function<RubberBandUGen, &RubberBandUGen::next>();
        next(1);
    }

    ~RubberBandUGen() {
        if (rubberband != NULL) {
            delete rubberband;
        }

        if (stretchInBuf) {
            for (int ch = 0; ch < numChannels; ch++) {
                if (stretchInBuf[ch]) RTFree(mWorld, stretchInBuf[ch]);
            }
            RTFree(mWorld, stretchInBuf);
        }
        if (stretchOutBuf) {
            for (int ch = 0; ch < numChannels; ch++) {
                if (stretchOutBuf[ch]) RTFree(mWorld, stretchOutBuf[ch]);
            }
            RTFree(mWorld, stretchOutBuf);
        }
    }

private:
    // The GET_BUF macro fills in these two:
    float m_fbufnum;
    SndBuf *m_buf;

    // state variables
    const int maxProcessSize = 512;
    const double minSpeedRatio = 0.000001;

    RubberBandStretcher *rubberband = NULL;
    int numChannels;
    int playheadPos;
    size_t startDelay;
    size_t samplesOutput;

    // Per-channel buffer arrays for RubberBandStretcher
    float **stretchInBuf = NULL;
    float **stretchOutBuf = NULL;


    // calc function
    void next(int inNumSamples) {
        // Alias `this` as `unit` for GET_BUF macro compatibility
        RubberBandUGen * unit = this;

        double rate = 1.0 / std::max((double)in(1)[0], minSpeedRatio);

        GET_BUF

        rubberband->setTimeRatio(rate);

        // Feed input using getSamplesRequired() pull pattern
        while (rubberband->available() < (int)inNumSamples + (int)startDelay) {

            if (playheadPos >= (int)bufFrames) {
                break;
            }

            size_t needed = rubberband->getSamplesRequired();
            if (needed == 0) break;

            // Clamp to maxProcessSize (our buffer allocation limit)
            int toProcess = (int)std::min(needed, (size_t)maxProcessSize);

            // De-interleave from the SndBuf into per-channel input buffers
            for (int ch = 0; ch < numChannels; ch++) {
                int i;
                for (i = 0; i < toProcess && (playheadPos + i) < (int)bufFrames; i++) {
                    stretchInBuf[ch][i] = bufData[(playheadPos + i) * bufChannels + ch];
                }
                // Zero-fill remainder if we hit the end of the buffer
                for (; i < toProcess; i++) {
                    stretchInBuf[ch][i] = 0.f;
                }
            }

            rubberband->process((const float *const *)stretchInBuf, toProcess, false);
            playheadPos += toProcess;
        }

        // Retrieve output -- skip startDelay samples at the beginning
        int avail = rubberband->available();

        // If we still need to skip delay samples, do so first.
        // Clamp to maxProcessSize since that's our buffer allocation.
        while (startDelay > 0 && avail > 0) {
            size_t toSkip = std::min({(size_t)avail, startDelay, (size_t)maxProcessSize});
            rubberband->retrieve(stretchOutBuf, toSkip);
            startDelay -= toSkip;
            avail = rubberband->available();
        }

        // Now retrieve the actual output
        size_t toRetrieve = std::min(avail > 0 ? (size_t)avail : (size_t)0, (size_t)inNumSamples);
        size_t samplesRetrieved = 0;
        if (toRetrieve > 0) {
            samplesRetrieved = rubberband->retrieve(stretchOutBuf, toRetrieve);
        }
        samplesOutput += samplesRetrieved;

        // Write to SC outputs (one output per channel)
        for (int ch = 0; ch < numChannels; ch++) {
            float *output = out(ch);
            for (size_t i = 0; i < samplesRetrieved; i++) {
                output[i] = stretchOutBuf[ch][i];
            }
            for (size_t i = samplesRetrieved; i < (size_t)inNumSamples; i++) {
                output[i] = 0.f;
            }
        }
    }

    void setupBuffers() {
        // Allocate per-channel input buffers
        stretchInBuf = (float **)RTAlloc(mWorld, numChannels * sizeof(float *));
        stretchOutBuf = (float **)RTAlloc(mWorld, numChannels * sizeof(float *));

        if (!stretchInBuf || !stretchOutBuf) {
            failAlloc();
            return;
        }

        for (int ch = 0; ch < numChannels; ch++) {
            stretchInBuf[ch] = (float *)RTAlloc(mWorld, maxProcessSize * sizeof(float));
            stretchOutBuf[ch] = (float *)RTAlloc(mWorld, maxProcessSize * sizeof(float));

            if (!stretchInBuf[ch] || !stretchOutBuf[ch]) {
                failAlloc();
                return;
            }

            memset(stretchInBuf[ch], 0, maxProcessSize * sizeof(float));
            memset(stretchOutBuf[ch], 0, maxProcessSize * sizeof(float));
        }

        rubberband->setMaxProcessSize(maxProcessSize);
    }

    void failAlloc() {
        RubberBandUGen *unit = this;
        SETCALC(ft->fClearUnitOutputs);
        ClearUnitOutputs(this, 1);
        if (mWorld->mVerbosity > -2) {
            Print("Failed to allocate memory for RubberBand ugen.\n");
        }
    }
};

PluginLoad(RubberBandUGens) {
    ft = inTable;
    registerUnit<RubberBandUGen>(ft, "RubberBand");
}
