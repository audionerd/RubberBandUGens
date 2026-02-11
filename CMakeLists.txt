set(FILENAME "RubberBand.cpp") #specify the .cpp file here
cmake_minimum_required (VERSION 2.8)
get_filename_component(PROJECT ${FILENAME} NAME_WE) #automatically sets project name from the filename
message(STATUS "Project name is ${PROJECT}")
project (${PROJECT})

# Try to find SuperCollider source: explicit flag, then local checkout, then common install paths
if(NOT SC_PATH)
    # Check for a local checkout in the project folder
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/supercollider/include/plugin_interface/SC_PlugIn.hpp")
        set(SC_PATH "${CMAKE_CURRENT_SOURCE_DIR}/supercollider")
    endif()
endif()
if(NOT SC_PATH)
    find_path(SC_PLUGIN_HEADER_DIR SC_PlugIn.hpp
        PATHS
            /usr/local/include/SuperCollider/plugin_interface
            /opt/homebrew/include/SuperCollider/plugin_interface
            /usr/include/SuperCollider/plugin_interface
    )
    if(SC_PLUGIN_HEADER_DIR)
        # Back up two levels: .../include/SuperCollider
        get_filename_component(SC_PATH "${SC_PLUGIN_HEADER_DIR}/../.." ABSOLUTE)
    endif()
endif()
if(NOT SC_PATH)
    message(FATAL_ERROR "Could not find SuperCollider source. Pass -DSC_PATH=/path/to/supercollider")
endif()
message(STATUS "SC_PATH is ${SC_PATH}")

include_directories(${SC_PATH}/include/plugin_interface)
include_directories(${SC_PATH}/include/common)
include_directories(${SC_PATH}/common)

# RubberBand headers (rubberband/RubberBandStretcher.h lives in rubberband/rubberband/)
include_directories(rubberband)
# Internal rubberband sources need includes relative to rubberband/
include_directories(rubberband/src)

set(CMAKE_SHARED_MODULE_PREFIX "")
if(APPLE OR WIN32)
set(CMAKE_SHARED_MODULE_SUFFIX ".scx")
endif()

option(SUPERNOVA "Build plugins for supernova" OFF)
if (SUPERNOVA)
    include_directories(${SC_PATH}/external_libraries/nova-tt)
    # actually just boost.atomic
    include_directories(${SC_PATH}/external_libraries/boost)
    include_directories(${SC_PATH}/external_libraries/boost_lockfree)
    include_directories(${SC_PATH}/external_libraries/boost-lockfree)
endif()

option(CPP11 "Build with c++11." ON)

if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
	set(CMAKE_COMPILER_IS_CLANG 1)
endif()

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_COMPILER_IS_CLANG)
    add_definitions(-fvisibility=hidden)

    include (CheckCCompilerFlag)
    include (CheckCXXCompilerFlag)

    CHECK_C_COMPILER_FLAG(-msse HAS_SSE)
    CHECK_CXX_COMPILER_FLAG(-msse HAS_CXX_SSE)

    if (HAS_SSE)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -msse")
    endif()
    if (HAS_CXX_SSE)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -msse")
    endif()

    CHECK_C_COMPILER_FLAG(-msse2 HAS_SSE2)
    CHECK_CXX_COMPILER_FLAG(-msse2 HAS_CXX_SSE2)

    if (HAS_SSE2)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -msse2")
    endif()
    if (HAS_CXX_SSE2)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -msse2")
    endif()

    CHECK_C_COMPILER_FLAG(-mfpmath=sse HAS_FPMATH_SSE)
    CHECK_CXX_COMPILER_FLAG(-mfpmath=sse HAS_CXX_FPMATH_SSE)

    if (HAS_FPMATH_SSE)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mfpmath=sse")
    endif()
    if (HAS_CXX_FPMATH_SSE)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mfpmath=sse")
    endif()

    if(NATIVE)
        add_definitions(-march=native)
    endif()

    if(CPP11)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
        if(CMAKE_COMPILER_IS_CLANG)
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
        endif()
    endif()
endif()
if(MINGW)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mstackrealign")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mstackrealign")
endif()

# ---------- RubberBand library sources (compiled directly into the plugin) ----------
set(RUBBERBAND_SRC
    rubberband/src/RubberBandStretcher.cpp
    rubberband/src/StretcherProcess.cpp
    rubberband/src/StretchCalculator.cpp
    rubberband/src/StretcherChannelData.cpp
    rubberband/src/StretcherImpl.cpp
    rubberband/src/rubberband-c.cpp
    rubberband/src/base/Profiler.cpp
    rubberband/src/dsp/AudioCurveCalculator.cpp
    rubberband/src/dsp/FFT.cpp
    rubberband/src/dsp/Resampler.cpp
    rubberband/src/audiocurves/CompoundAudioCurve.cpp
    rubberband/src/audiocurves/SpectralDifferenceAudioCurve.cpp
    rubberband/src/audiocurves/HighFrequencyAudioCurve.cpp
    rubberband/src/audiocurves/SilentAudioCurve.cpp
    rubberband/src/audiocurves/ConstantAudioCurve.cpp
    rubberband/src/audiocurves/PercussiveAudioCurve.cpp
    rubberband/src/system/Allocators.cpp
    rubberband/src/system/sysutils.cpp
    rubberband/src/system/Thread.cpp
    rubberband/src/system/VectorOpsComplex.cpp
    rubberband/src/speex/resample.c
)

# RubberBand compile definitions (from Makefile.osx)
add_definitions(
    -DUSE_PTHREADS
    -DMALLOC_IS_ALIGNED
    -DUSE_SPEEX
    -DNO_THREAD_CHECKS
    -DNO_TIMING
)
if(APPLE)
    add_definitions(-DHAVE_VDSP)
endif()

add_library(${PROJECT} MODULE ${FILENAME} ${RUBBERBAND_SRC})

# Link frameworks/libraries
if(APPLE)
    target_link_libraries(${PROJECT} "-framework Accelerate")
endif()
target_link_libraries(${PROJECT} pthread)

if(SUPERNOVA)
    add_library(${PROJECT}_supernova MODULE ${FILENAME} ${RUBBERBAND_SRC})
    set_property(TARGET ${PROJECT}_supernova
                 PROPERTY COMPILE_DEFINITIONS SUPERNOVA)
    if(APPLE)
        target_link_libraries(${PROJECT}_supernova "-framework Accelerate")
    endif()
    target_link_libraries(${PROJECT}_supernova pthread)
endif()
