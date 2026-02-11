cmake_minimum_required(VERSION 3.5)
project(RubberBandUGens)

# --- Find SuperCollider source ---
if(NOT SC_PATH)
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
        get_filename_component(SC_PATH "${SC_PLUGIN_HEADER_DIR}/../.." ABSOLUTE)
    endif()
endif()
if(NOT SC_PATH)
    message(FATAL_ERROR "Could not find SuperCollider source. Pass -DSC_PATH=/path/to/supercollider")
endif()
message(STATUS "SC_PATH is ${SC_PATH}")

# --- Compiler setup ---
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_SHARED_MODULE_PREFIX "")
if(APPLE OR WIN32)
    set(CMAKE_SHARED_MODULE_SUFFIX ".scx")
endif()

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
    add_compile_options(-fvisibility=hidden)
    if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        add_compile_options(-stdlib=libc++)
        add_link_options(-stdlib=libc++)
    endif()
endif()
if(WIN32)
    add_definitions(-DNOMINMAX)
endif()

# --- Include paths ---
include_directories(
    ${SC_PATH}/include/plugin_interface
    ${SC_PATH}/include/common
    ${SC_PATH}/common
    rubberband
)

option(SUPERNOVA "Build plugins for supernova" OFF)
if(SUPERNOVA)
    include_directories(
        ${SC_PATH}/external_libraries/nova-tt
        ${SC_PATH}/external_libraries/boost
        ${SC_PATH}/external_libraries/boost_lockfree
        ${SC_PATH}/external_libraries/boost-lockfree
    )
endif()

# --- RubberBand library (v4.0 single compilation unit) ---
set(RUBBERBAND_SRC rubberband/single/RubberBandSingle.cpp)

# --- Plugin sources ---
set(PLUGIN_SRC plugins/RubberBand/RubberBand.cpp)

# --- Build targets ---
add_library(RubberBand MODULE ${PLUGIN_SRC} ${RUBBERBAND_SRC})
if(APPLE)
    target_link_libraries(RubberBand "-framework Accelerate")
endif()

if(SUPERNOVA)
    add_library(RubberBand_supernova MODULE ${PLUGIN_SRC} ${RUBBERBAND_SRC})
    target_compile_definitions(RubberBand_supernova PRIVATE SUPERNOVA)
    if(APPLE)
        target_link_libraries(RubberBand_supernova "-framework Accelerate")
    endif()
endif()

# --- Install target ---
# Installs the .scx plugin and .sc class file into an Extensions-ready directory
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/Install" CACHE PATH "Install path" FORCE)
endif()

install(TARGETS RubberBand LIBRARY DESTINATION "RubberBand")
install(FILES plugins/RubberBand/RubberBand.sc DESTINATION "RubberBand/Classes")
if(SUPERNOVA)
    install(TARGETS RubberBand_supernova LIBRARY DESTINATION "RubberBand")
endif()
