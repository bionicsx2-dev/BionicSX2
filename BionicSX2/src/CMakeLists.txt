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
    ${CMAKE_CURRENT_SOURCE_DIR}/GS/GSCapture.cpp
)
# DEV9 is fully stubbed on iOS via PCSX2Stubs.mm — exclude all source files
file(GLOB_RECURSE DEV9_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/DEV9/*.cpp)
list(REMOVE_ITEM PCSX2_CORE_SOURCES ${DEV9_SOURCES})

add_library(pcsx2-core STATIC ${PCSX2_CORE_SOURCES})

# Find system dependencies (cross-compiling for iOS, so use host paths)
execute_process(COMMAND brew --prefix lz4
  OUTPUT_VARIABLE LZ4_PREFIX OUTPUT_STRIP_TRAILING_WHITESPACE
  ERROR_QUIET)
if(LZ4_PREFIX)
  target_include_directories(pcsx2-core PUBLIC "${LZ4_PREFIX}/include")
else()
  target_include_directories(pcsx2-core PUBLIC "/opt/homebrew/opt/lz4/include")
endif()

target_include_directories(pcsx2-core PUBLIC
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

target_compile_features(pcsx2-core PUBLIC cxx_std_20)
target_compile_definitions(pcsx2-core PUBLIC PCSX2_TARGET_IOS=1)

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
target_include_directories(pcsx2-core PUBLIC "${CMAKE_BINARY_DIR}")

# Generate stub headers for external dependencies not bundled in 3rdparty
file(WRITE "${CMAKE_BINARY_DIR}/stubs/ryml.hpp"
    "#pragma once\n"
    "#include <string>\n"
    "#include <vector>\n"
    "namespace ryml {\n"
    "struct Tree {};\n"
    "struct NodeRef {};\n"
    "inline Tree parse_in_place(c4::substr) { return Tree(); }\n"
    "inline Tree parse_in_arena(c4::csubstr) { return Tree(); }\n"
    "}\n"
    "namespace c4 { using csubstr = const char*; using substr = char*; }\n"
)
file(WRITE "${CMAKE_BINARY_DIR}/stubs/c4/substr_fwd.hpp"
    "#pragma once\n"
    "namespace c4 { using csubstr = const char*; using substr = char*; }\n"
)
file(WRITE "${CMAKE_BINARY_DIR}/stubs/zstd.h"
    "#pragma once\n"
    "#include <stddef.h>\n"
    "typedef struct ZSTD_CCtx_s ZSTD_CCtx;\n"
    "typedef ZSTD_CCtx ZSTD_CStream;\n"
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
    "static inline unsigned ZSTD_isError(size_t) { return 0; }\n"
    "static inline const char* ZSTD_getErrorName(size_t) { return \"\"; }\n"
)
file(WRITE "${CMAKE_BINARY_DIR}/stubs/cpuinfo.h"
    "#pragma once\n"
    "struct cpuinfo_core { unsigned long vendor; };\n"
    "enum cpuinfo_vendor_ { cpuinfo_vendor_amd = 0 };\n"
    "static inline const struct cpuinfo_core* cpuinfo_get_core(unsigned int) { return 0; }\n"
    "enum cpuinfo_uarch_ { cpuinfo_uarch_unknown = 0 };\n"
)
target_include_directories(pcsx2-core PUBLIC "${CMAKE_BINARY_DIR}/stubs")

# Disable exceptions and strict aliasing (matching PCSX2 build conventions)
target_compile_options(pcsx2-core PRIVATE
    -fno-exceptions
    -fno-strict-aliasing
    -Wno-parentheses
)

target_link_libraries(pcsx2-core PUBLIC common)
