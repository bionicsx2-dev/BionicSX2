# BionicSX2 iOS Platform Layer
# AUDIT REFERENCE: Section 13.3
# Only compile files that are NOT already in common/ library.
# Files already in common: DarwinThreads.cpp, DarwinMisc.cpp (PageFaultHandler), LnxHostSys.cpp
# These exist on disk for reference but are excluded from this build target.

add_library(ios-platform STATIC
    platform/iOSVMManager.mm
    platform/CocoaTools.mm
    platform/AudioStream_iOS.cpp
    platform/Filesystem_iOS.cpp
    platform/Host_iOS.mm
    platform/PCSX2Stubs.mm
)

target_include_directories(ios-platform PUBLIC
    ${CMAKE_SOURCE_DIR}/src
    ${PCSX2_ROOT}/common
    ${PCSX2_ROOT}/3rdparty/include
    ${PCSX2_ROOT}/3rdparty/fmt/include
    ${PCSX2_ROOT}/3rdparty/fast_float/include
    ${CMAKE_BINARY_DIR}
    ${CMAKE_BINARY_DIR}/stubs
)

target_compile_features(ios-platform PUBLIC cxx_std_20)
target_compile_definitions(ios-platform PUBLIC PCSX2_TARGET_IOS=1)
