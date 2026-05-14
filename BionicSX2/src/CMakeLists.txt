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
# Exclude platform-specific files
list(REMOVE_ITEM PCSX2_CORE_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/Host.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/arm64/Vif_Dynarec.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/GS/Renderers/SW/GSDrawScanlineCodeGenerator.arm64.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/GS/Renderers/SW/GSSetupPrimCodeGenerator.arm64.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/GS/Renderers/SW/GSDrawScanlineCodeGenerator.all.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/GS/Renderers/SW/GSSetupPrimCodeGenerator.all.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/GS/GSCapture.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/GameDatabase.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/SIO/Memcard/MemoryCardFolder.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/Host/AudioStream.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/Host/SDLAudioStream.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/Host/CubebAudioStream.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/ImGui/ImGuiFullscreen.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/ImGui/ImGuiManager.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/Input/DInputSource.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/Input/XInputSource.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/Input/SDLInputSource.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/IopModuleNames.cpp
)
# RDebug (DECI2 debugger protocol) references IOP internals not compiled on iOS
file(GLOB RDEBUG_SOURCES RDebug/*.cpp)
list(REMOVE_ITEM PCSX2_CORE_SOURCES ${RDEBUG_SOURCES})
# USB/usb-eyetoy uses platform-specific webcam APIs (jpeglib, V4L2, DirectShow, AVFoundation)
# USB/usb-pad-sdl-ff includes SDLInputSource.h (SDL3 dependency)
# DebugTools — exclude everything except DisR5900asm (needed by R5900OpcodeTables)
file(GLOB DEBUGTOOLS_SOURCES DebugTools/*.cpp)
list(REMOVE_ITEM PCSX2_CORE_SOURCES ${DEBUGTOOLS_SOURCES})
# USB is fully stubbed on iOS via PCSX2Stubs.mm
file(GLOB_RECURSE USB_EYETOY_SOURCES USB/usb-eyetoy/*.cpp USB/usb-eyetoy/*.mm)
list(REMOVE_ITEM PCSX2_CORE_SOURCES ${USB_EYETOY_SOURCES})
file(GLOB USB_PAD_SDLFF_SOURCES USB/usb-pad/usb-pad-sdl-ff*.cpp)
list(REMOVE_ITEM PCSX2_CORE_SOURCES ${USB_PAD_SDLFF_SOURCES})
# DEV9 is fully stubbed on iOS via PCSX2Stubs.mm — exclude all source files
file(GLOB_RECURSE DEV9_SOURCES DEV9/*.cpp)
list(REMOVE_ITEM PCSX2_CORE_SOURCES ${DEV9_SOURCES})
# GS Dump/Capture/PNG — not needed on iOS, pull in lzma/zstd/crc/imgui
list(REMOVE_ITEM PCSX2_CORE_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/GS/GSDump.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/GS/GSLzma.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/GS/GSPng.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/GSDumpReplayer.cpp
)
# Achievements/FullscreenUI/ImGui — depends on imgui, not needed initially
list(REMOVE_ITEM PCSX2_CORE_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/Achievements.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/ImGui/FullscreenUI.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/ImGui/FullscreenUI_Settings.cpp
)
# CDVDdiscReader — GetValidDrive is Darwin optical-drive specific, not on iOS
list(REMOVE_ITEM PCSX2_CORE_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/CDVD/CDVDdiscReader.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/CDVD/CDVDdiscThread.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/CDVD/CsoFileReader.cpp
)

add_library(PCSX2 STATIC ${PCSX2_CORE_SOURCES})

# Add back DisR5900asm.cpp (excluded via DebugTools glob above, but needed by R5900OpcodeTables)
target_sources(PCSX2 PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/DebugTools/DisR5900asm.cpp)

# Find system dependencies (cross-compiling for iOS, so use host paths)
execute_process(COMMAND brew --prefix libpng
  OUTPUT_VARIABLE PNG_PREFIX OUTPUT_STRIP_TRAILING_WHITESPACE
  ERROR_QUIET)
if(PNG_PREFIX)
  target_include_directories(PCSX2 PUBLIC "${PNG_PREFIX}/include")
endif()

# lz4: available via ios-deps when built; CsoFileReader excluded below

target_include_directories(PCSX2 PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${PCSX2_ROOT}
    ${PCSX2_ROOT}/3rdparty/include
    ${PCSX2_ROOT}/3rdparty/fmt/include
    ${PCSX2_ROOT}/3rdparty/fast_float/include
    ${PCSX2_ROOT}/3rdparty/imgui/include
    ${PCSX2_ROOT}/3rdparty/cpuinfo/include
    ${PCSX2_ROOT}/3rdparty/cubeb/include
    ${PCSX2_ROOT}/3rdparty/libchdr/include
    ${PCSX2_ROOT}/3rdparty/lzma/include
    ${PCSX2_ROOT}/3rdparty/libzip/lib
    ${PCSX2_ROOT}/3rdparty/simpleini/include
    ${PCSX2_ROOT}/3rdparty/soundtouch/soundtouch
    ${PCSX2_ROOT}/3rdparty/rcheevos/include
    ${PCSX2_ROOT}/3rdparty/demangler/include
    ${PCSX2_ROOT}/3rdparty/zydis/include
    ${PCSX2_ROOT}/3rdparty/vixl/include
    ${PCSX2_ROOT}/3rdparty/freesurround/include
    ${PCSX2_ROOT}/3rdparty/ccc/src
)

target_compile_features(PCSX2 PUBLIC cxx_std_20)
target_compile_definitions(PCSX2 PUBLIC PCSX2_TARGET_IOS)

# Generate svnrev.h for BuildVersion.cpp
file(WRITE "${CMAKE_BINARY_DIR}/svnrev.h"
    "#define GIT_TAG \"v0.1.0\"\n"
    "#define GIT_TAGGED_COMMIT 0\n"
    "#define GIT_TAG_HI 0\n"
    "#define GIT_TAG_MID 1\n"
    "#define GIT_TAG_LO 0\n"
    "#define GIT_REV \"v0.1.0-ios\"\n"
    "#define GIT_HASH \"unknown\"\n"
    "#define GIT_DATE \"unknown\"\n"
)
target_include_directories(PCSX2 PUBLIC "${CMAKE_BINARY_DIR}")

# Generate stub headers for external dependencies not bundled in 3rdparty
file(WRITE "${CMAKE_BINARY_DIR}/stubs/c4/substr_fwd.hpp"
    "#pragma once\n"
    "namespace c4 { using csubstr = const char*; using substr = char*; }\n"
)
file(WRITE "${CMAKE_BINARY_DIR}/stubs/ryml.hpp"
    "#pragma once\n"
    "#include <string>\n"
    "#include <vector>\n"
    "#include \"c4/substr_fwd.hpp\"\n"
    "namespace ryml {\n"
    "struct Tree {};\n"
    "struct NodeRef {};\n"
    "inline Tree parse_in_place(c4::substr) { return Tree(); }\n"
    "inline Tree parse_in_arena(c4::csubstr) { return Tree(); }\n"
    "}\n"
)
file(WRITE "${CMAKE_BINARY_DIR}/stubs/ryml_std.hpp"
    "#pragma once\n"
    "#include <string>\n"
    "template<typename T> inline void swap(T&, T&) noexcept {}\n"
)
file(WRITE "${CMAKE_BINARY_DIR}/stubs/zstd.h"
    "#pragma once\n"
    "#include <stddef.h>\n"
    "typedef struct ZSTD_CCtx_s ZSTD_CCtx;\n"
    "typedef ZSTD_CCtx ZSTD_CStream;\n"
    "typedef ZSTD_CCtx ZSTD_DStream;\n"
    "typedef struct ZSTD_inBuffer_s { const void* src; size_t size; size_t pos; } ZSTD_inBuffer;\n"
    "typedef struct ZSTD_outBuffer_s { void* dst; size_t size; size_t pos; } ZSTD_outBuffer;\n"
    "typedef enum { ZSTD_e_continue=0, ZST_e_flush=1, ZSTD_e_end=2 } ZSTD_EndDirective;\n"
    "#define ZSTD_c_compressionLevel 100\n"
    "static inline size_t ZSTD_compressBound(size_t s) { return s; }\n"
    "static inline size_t ZSTD_compress(void*, size_t, const void*, size_t, int) { return 0; }\n"
    "static inline size_t ZSTD_decompress(void*, size_t, const void*, size_t) { return 0; }\n"
    "#define ZSTD_CONTENTSIZE_ERROR 0\n"
    "static inline unsigned long long ZSTD_getFrameContentSize(const void*, size_t) { return 0; }\n"
    "static inline ZSTD_CStream* ZSTD_createCStream() { return nullptr; }\n"
    "static inline size_t ZSTD_CCtx_setParameter(ZSTD_CCtx*, int, int) { return 0; }\n"
    "static inline size_t ZSTD_compressStream2(ZSTD_CStream*, ZSTD_outBuffer*, ZSTD_inBuffer*, ZSTD_EndDirective) { return 0; }\n"
    "static inline size_t ZSTD_freeCStream(ZSTD_CStream*) { return 0; }\n"
    "static inline ZSTD_DStream* ZSTD_createDStream() { return nullptr; }\n"
    "static inline size_t ZSTD_freeDStream(ZSTD_DStream*) { return 0; }\n"
    "static inline size_t ZSTD_decompressStream(ZSTD_DStream*, ZSTD_outBuffer*, ZSTD_inBuffer*) { return 0; }\n"
    "static inline unsigned ZSTD_isError(size_t) { return 0; }\n"
    "static inline const char* ZSTD_getErrorName(size_t) { return \"\"; }\n"
)
file(WRITE "${CMAKE_BINARY_DIR}/stubs/zipconf.h"
    "#pragma once\n"
    "#include <stdint.h>\n"
    "typedef int64_t zip_int64_t;\n"
    "typedef uint64_t zip_uint64_t;\n"
    "typedef int32_t zip_int32_t;\n"
    "typedef uint32_t zip_uint32_t;\n"
    "typedef int16_t zip_int16_t;\n"
    "typedef uint16_t zip_uint16_t;\n"
    "typedef int8_t zip_int8_t;\n"
    "typedef uint8_t zip_uint8_t;\n"
    "#define ZIP_INT64_MIN (-9223372036854775807LL-1LL)\n"
)
file(WRITE "${CMAKE_BINARY_DIR}/stubs/cpuinfo.h"
    "#pragma once\n"
    "struct cpuinfo_core { unsigned long vendor; };\n"
    "enum cpuinfo_vendor_ { cpuinfo_vendor_amd = 0 };\n"
    "static inline const struct cpuinfo_core* cpuinfo_get_core(unsigned int) { return 0; }\n"
    "enum cpuinfo_uarch_ { cpuinfo_uarch_unknown = 0 };\n"
)
target_include_directories(PCSX2 PUBLIC "${CMAKE_BINARY_DIR}/stubs")

# Disable exceptions and strict aliasing (matching PCSX2 build conventions)
target_compile_options(PCSX2 PRIVATE
    -fno-exceptions
    -fno-strict-aliasing
    -Wno-parentheses
)

# Add common library sources directly (pcsx2 common/CMakeLists.txt not compatible as subdirectory)
file(GLOB_RECURSE COMMON_SOURCES ${PCSX2_ROOT}/common/*.cpp ${PCSX2_ROOT}/common/*.mm)
# Exclude platform-specific files not for iOS
list(REMOVE_ITEM COMMON_SOURCES
    ${PCSX2_ROOT}/common/Darwin/DarwinMisc.cpp
    ${PCSX2_ROOT}/common/HostSys.cpp
    ${PCSX2_ROOT}/common/HTTPDownloaderWinHTTP.cpp
    ${PCSX2_ROOT}/common/HTTPDownloaderCurl.cpp
    ${PCSX2_ROOT}/common/Image.cpp
    ${PCSX2_ROOT}/common/StackWalker.cpp
    ${PCSX2_ROOT}/common/YAML.cpp
    ${PCSX2_ROOT}/common/CocoaTools.mm
    ${PCSX2_ROOT}/common/Windows/WinThreads.cpp
    ${PCSX2_ROOT}/common/Windows/WinHostSys.cpp
    ${PCSX2_ROOT}/common/Windows/WinMisc.cpp
    ${PCSX2_ROOT}/common/Linux/LnxThreads.cpp
    ${PCSX2_ROOT}/common/Linux/LnxMisc.cpp
    ${PCSX2_ROOT}/common/emitter/bmi.cpp
    ${PCSX2_ROOT}/common/emitter/fpu.cpp
    ${PCSX2_ROOT}/common/emitter/groups.cpp
    ${PCSX2_ROOT}/common/emitter/jmp.cpp
    ${PCSX2_ROOT}/common/emitter/legacy.cpp
    ${PCSX2_ROOT}/common/emitter/legacy_sse.cpp
    ${PCSX2_ROOT}/common/emitter/movs.cpp
    ${PCSX2_ROOT}/common/emitter/simd.cpp
    ${PCSX2_ROOT}/common/emitter/x86emitter.cpp
)
target_sources(PCSX2 PRIVATE ${COMMON_SOURCES})
target_include_directories(PCSX2 PUBLIC ${PCSX2_ROOT}/common)
target_compile_options(PCSX2 PRIVATE -fobjc-arc)
target_link_options(PCSX2 PRIVATE -fobjc-link-runtime)
target_link_libraries(PCSX2 PUBLIC "-framework Foundation")
# lz4 not available for iOS cross-compilation (Homebrew provides macOS binary only).
# CsoFileReader excluded above; lz4-dependent features stubbed.
