#include <algorithm>
#include <cstring>

#include "SC_PlugIn.hpp"
#include <rubberband/RubberBandStretcher.h>

using namespace RubberBand;

static InterfaceTable *ft;

// Input indices (after bufnum which is read by GET_BUF at index 0)
enum {
    kBufNum = 0,    // bufnum — read by GET_BUF
    kRate,          // playback speed (1.0 = normal)
    kPitchShift,    // pitch scale (1.0 = no shift, 2.0 = octave up)
    kTrig,          // positive transition resets playhead to startPos
    kStartPos,      // start position in frames (reset target for trig)
    kLoop,          // loop mode (0 = off, 1 = on)
    kDoneAction,    // done action when buffer playback finishes (non-loop)
    kFormant        // formant preservation (0 = shifted, 1 = preserved)
};

struct RubberBandUGen : public SCUnit {
public:
    RubberBandUGen() {
        numChannels = (int)numOutputs();

        // Read initial values for construction
        double rate = std::max((double)in(kRate)[0], minSpeedRatio);
        double pitchScale = clampPitch((double)in(kPitchShift)[0]);
        int formant = (int)in(kFormant)[0];

        // Build constructor options.
        // OptionPitchHighConsistency is required for smooth, glitch-free
        // time-varying pitch shifts (e.g. LFO or mouse modulation).
        int options =
            RubberBandStretcher::OptionProcessRealTime |
            RubberBandStretcher::OptionThreadingNever |
            RubberBandStretcher::OptionPitchHighConsistency;

        if (formant)
            options |= RubberBandStretcher::OptionFormantPreserved;

        rubberband = new RubberBandStretcher(
            sampleRate(),
            numChannels,
            options
        );

        // setMaxProcessSize MUST be called before setTimeRatio / setPitchScale
        // and before the first process() call.
        setupBuffers();
        if (allocFailed) return;

        rubberband->setTimeRatio(1.0 / rate);
        rubberband->setPitchScale(pitchScale);

        primeStretcher();

        playheadPos = (int)in(kStartPos)[0];
        prevTrig = in(kTrig)[0];
        prevFormant = formant;
        playbackDone = false;
        samplesOutput = 0;

        // set_calc_function sets the calc function AND calls next(1) internally.
        set_calc_function<RubberBandUGen, &RubberBandUGen::next>();
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
    // Required by GET_BUF macro (init m_fbufnum to -1 so first GET_BUF
    // always does the full buffer lookup instead of using uninitialized m_buf)
    float m_fbufnum = -1.f;
    SndBuf *m_buf = nullptr;

    // Constants
    const int maxProcessSize = 8192;
    const double minSpeedRatio = 0.000001;
    const double minPitchScale = 0.0625;  // ~4 octaves down
    const double maxPitchScale = 16.0;    // ~4 octaves up

    // State
    RubberBandStretcher *rubberband = NULL;
    int numChannels;
    int playheadPos;
    size_t startDelay;
    size_t samplesOutput;
    float prevTrig;
    int prevFormant;
    bool playbackDone;
    bool allocFailed = false;

    // Per-channel buffer arrays for RubberBandStretcher
    float **stretchInBuf = NULL;
    float **stretchOutBuf = NULL;

    // Clamp pitch scale to safe range
    double clampPitch(double p) const {
        return std::max(minPitchScale, std::min(maxPitchScale, p));
    }

    // Feed silence into the stretcher to satisfy the preferred start pad,
    // then record the start delay so we can skip those initial samples.
    void primeStretcher() {
        size_t startPad = rubberband->getPreferredStartPad();
        if (startPad > 0) {
            // Ensure input buffers are zeroed for silent priming
            for (int ch = 0; ch < numChannels; ch++) {
                memset(stretchInBuf[ch], 0, maxProcessSize * sizeof(float));
            }
            size_t remaining = startPad;
            while (remaining > 0) {
                size_t chunk = std::min(remaining, (size_t)maxProcessSize);
                rubberband->process((const float *const *)stretchInBuf, chunk, false);
                remaining -= chunk;
            }
        }
        startDelay = rubberband->getStartDelay();
    }

    // ---------- calc function ----------
    void next(int inNumSamples) {
        // Alias for GET_BUF macro compatibility
        RubberBandUGen *unit = this;

        // Read control inputs (first sample of each)
        double rate    = std::max((double)in(kRate)[0], minSpeedRatio);
        double pitch   = clampPitch((double)in(kPitchShift)[0]);
        float  trigVal = in(kTrig)[0];
        int    startP  = (int)in(kStartPos)[0];
        int    loop    = (int)in(kLoop)[0];
        int    doneAct = (int)in(kDoneAction)[0];
        int    formant = (int)in(kFormant)[0];

        GET_BUF

        // --- Handle trigger: positive transition resets playback ---
        if (trigVal > 0.f && prevTrig <= 0.f) {
            // Clamp startPos into buffer range
            playheadPos = std::max(0, std::min(startP, (int)bufFrames - 1));
            playbackDone = false;
            samplesOutput = 0;
            rubberband->reset();
            primeStretcher();
        }
        prevTrig = trigVal;

        // --- Update formant option at runtime if it changed ---
        if (formant != prevFormant) {
            rubberband->setFormantOption(
                formant
                    ? RubberBandStretcher::OptionFormantPreserved
                    : RubberBandStretcher::OptionFormantShifted
            );
            prevFormant = formant;
        }

        // --- Set time ratio and pitch scale ---
        rubberband->setTimeRatio(1.0 / rate);
        rubberband->setPitchScale(pitch);

        // --- Feed input using getSamplesRequired() pull pattern ---
        while (rubberband->available() < (int)inNumSamples + (int)startDelay) {

            if (playheadPos >= (int)bufFrames) {
                if (loop) {
                    playheadPos = 0;
                } else {
                    break;
                }
            }

            size_t needed = rubberband->getSamplesRequired();
            if (needed == 0) break;

            int toProcess = (int)std::min(needed, (size_t)maxProcessSize);

            // De-interleave from the SndBuf into per-channel input buffers,
            // handling loop wrap-around and channel count mismatch.
            for (int ch = 0; ch < numChannels; ch++) {
                for (int i = 0; i < toProcess; i++) {
                    int pos = playheadPos + i;

                    // Wrap around if looping
                    if (pos >= (int)bufFrames) {
                        if (loop) {
                            pos = pos % (int)bufFrames;
                        } else {
                            stretchInBuf[ch][i] = 0.f;
                            continue;
                        }
                    }

                    // Safe channel read — zero-fill if UGen has more
                    // channels than the buffer
                    if (ch < (int)bufChannels) {
                        stretchInBuf[ch][i] = bufData[pos * bufChannels + ch];
                    } else {
                        stretchInBuf[ch][i] = 0.f;
                    }
                }
            }

            rubberband->process((const float *const *)stretchInBuf, toProcess, false);

            // Advance playhead, wrap if looping
            playheadPos += toProcess;
            if (loop && playheadPos >= (int)bufFrames) {
                playheadPos = playheadPos % (int)bufFrames;
            }
        }

        // --- Retrieve output: skip startDelay samples first ---
        int avail = rubberband->available();

        while (startDelay > 0 && avail > 0) {
            size_t toSkip = std::min({(size_t)avail, startDelay, (size_t)maxProcessSize});
            rubberband->retrieve(stretchOutBuf, toSkip);
            startDelay -= toSkip;
            avail = rubberband->available();
        }

        // Retrieve actual output
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

        // --- Done action: fire once when playback ends (non-looping) ---
        if (!loop && !playbackDone && playheadPos >= (int)bufFrames && avail <= 0) {
            playbackDone = true;
            if (doneAct > 0) {
                DoneAction(doneAct, this);
            }
        }
    }

    // ---------- buffer allocation ----------
    void setupBuffers() {
        stretchInBuf = (float **)RTAlloc(mWorld, numChannels * sizeof(float *));
        stretchOutBuf = (float **)RTAlloc(mWorld, numChannels * sizeof(float *));

        if (!stretchInBuf || !stretchOutBuf) {
            failAlloc();
            return;
        }

        // Zero the pointer arrays so the destructor is safe if we fail partway
        memset(stretchInBuf, 0, numChannels * sizeof(float *));
        memset(stretchOutBuf, 0, numChannels * sizeof(float *));

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
        allocFailed = true;
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
