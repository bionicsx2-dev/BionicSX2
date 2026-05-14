# PORTED FROM: pcsx2/pcsx2/CMakeLists.txt — BionicSX2 iOS Port
# AUDIT REFERENCE: Section 13.2 (GREEN files from core emulator),
#                  Section 2.1-2.6 (EE, VU, IOP, GS, SPU2, CDVD, PAD)
# STATUS: GREEN — compiled as-is on ARM64

# Core emulator library — all GREEN files per Audit Section 13.7
file(GLOB_RECURSE PCSX2_CORE_SOURCES
    *.cpp
    *.mm
    *.c
)

# Exclude files that should never compile on iOS
# Host.cpp is replaced by ios/platform/Host_iOS.mm (Audit Phase 0-F Category 7)
# arm64/Vif_Dynarec.cpp is excluded per Audit Section 2.3-F
# SW renderer JIT files excluded per Phase 0-B
list(REMOVE_ITEM PCSX2_CORE_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/Host.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/arm64/Vif_Dynarec.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/GS/Renderers/SW/GSDrawScanlineCodeGenerator.arm64.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/GS/Renderers/SW/GSSetupPrimCodeGenerator.arm64.cpp
)

add_library(pcsx2-core STATIC ${PCSX2_CORE_SOURCES})

target_include_directories(pcsx2-core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${PCSX2_ROOT}/common
    ${PCSX2_ROOT}/3rdparty/include
)

target_compile_features(pcsx2-core PUBLIC cxx_std_17)
target_compile_definitions(pcsx2-core PUBLIC PCSX2_TARGET_IOS=1)

# Disable exceptions and strict aliasing (matching PCSX2 build conventions)
target_compile_options(pcsx2-core PRIVATE
    -fno-exceptions
    -fno-strict-aliasing
    -Wno-parentheses
)

target_link_libraries(pcsx2-core PUBLIC common)
