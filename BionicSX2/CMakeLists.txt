cmake_minimum_required(VERSION 3.20)

# Toolchain must be set before project() — also pass via -DCMAKE_TOOLCHAIN_FILE on CLI
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_SOURCE_DIR}/cmake/ios.toolchain.cmake")

project(BionicSX2 C CXX OBJC OBJCXX Swift)
set(CMAKE_OSX_ARCHITECTURES arm64)
set(CMAKE_OSX_DEPLOYMENT_TARGET 16.0)
set(PCSX2_ROOT "${CMAKE_SOURCE_DIR}/../pcsx2")

add_definitions(-DPCSX2_TARGET_IOS)
add_definitions(-DTARGET_OS_IOS)
add_definitions(-DVIXL_CODE_BUFFER_MMAP)

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    set(IOS_DEPS "${CMAKE_SOURCE_DIR}/ios-deps/install")

    set(ENABLE_QT       OFF CACHE BOOL "" FORCE)
    set(ENABLE_OPENGL   OFF CACHE BOOL "" FORCE)
    set(ENABLE_VULKAN   OFF CACHE BOOL "" FORCE)
    set(USE_SDL         OFF CACHE BOOL "" FORCE)
    set(BUILD_TESTS     OFF CACHE BOOL "" FORCE)

    list(PREPEND CMAKE_PREFIX_PATH "${IOS_DEPS}")

    find_library(LZ4_LIB        lz4         PATHS "${IOS_DEPS}/lib" NO_DEFAULT_PATH)
    find_library(ZSTD_LIB       zstd        PATHS "${IOS_DEPS}/lib" NO_DEFAULT_PATH)
    find_library(LZMA_LIB       lzma        PATHS "${IOS_DEPS}/lib" NO_DEFAULT_PATH)
    find_library(ZIP_LIB        zip         PATHS "${IOS_DEPS}/lib" NO_DEFAULT_PATH)
    find_library(CHDR_LIB       chdr-static PATHS "${IOS_DEPS}/lib" NO_DEFAULT_PATH)
    find_library(CUBEB_LIB      cubeb       PATHS "${IOS_DEPS}/lib" NO_DEFAULT_PATH)
    find_library(SOUNDTOUCH_LIB SoundTouch  PATHS "${IOS_DEPS}/lib" NO_DEFAULT_PATH)

    find_library(PNG_LIBRARY    png16       PATHS "${IOS_DEPS}/lib" NO_DEFAULT_PATH)
    find_library(ZLIB_LIBRARY   z           PATHS "${IOS_DEPS}/lib" NO_DEFAULT_PATH)
endif()

# ── Core emulator library ──
add_subdirectory(src)

# ── iOS platform layer ──
add_subdirectory(ios)

# ── Metal rendering backend ──
add_subdirectory(metal)

# ── Final executable target ──
add_executable(BionicSX2 MACOSX_BUNDLE)

target_link_libraries(BionicSX2 PRIVATE
    PCSX2
    ios-platform
    metal-backend
)

# ── Link frameworks ──
find_library(METAL_LIBRARY Metal)
find_library(METALKIT_LIBRARY MetalKit)
find_library(AVFOUNDATION_LIBRARY AVFoundation)
find_library(GAMECONTROLLER_LIBRARY GameController)
find_library(FOUNDATION_LIBRARY Foundation)
find_library(UIKIT_LIBRARY UIKit)
find_library(QUARTZCORE_LIBRARY QuartzCore)
find_library(AUDIOTOOLBOX_LIBRARY AudioToolbox)
find_library(COREAUDIO_LIBRARY CoreAudio)
find_library(SECURITY_LIBRARY Security)

target_link_libraries(BionicSX2 PRIVATE
    ${METAL_LIBRARY}
    ${METALKIT_LIBRARY}
    ${AVFOUNDATION_LIBRARY}
    ${GAMECONTROLLER_LIBRARY}
    ${FOUNDATION_LIBRARY}
    ${UIKIT_LIBRARY}
    ${QUARTZCORE_LIBRARY}
    ${AUDIOTOOLBOX_LIBRARY}
    ${COREAUDIO_LIBRARY}
    ${SECURITY_LIBRARY}
)

# ── Link ios-deps (if built) ──
if(LZ4_LIB)
    target_link_libraries(BionicSX2 PRIVATE ${LZ4_LIB})
endif()
if(ZSTD_LIB)
    target_link_libraries(BionicSX2 PRIVATE ${ZSTD_LIB})
endif()
if(LZMA_LIB)
    target_link_libraries(BionicSX2 PRIVATE ${LZMA_LIB})
endif()
if(ZIP_LIB)
    target_link_libraries(BionicSX2 PRIVATE ${ZIP_LIB})
endif()
if(CHDR_LIB)
    target_link_libraries(BionicSX2 PRIVATE ${CHDR_LIB})
endif()
if(CUBEB_LIB)
    target_link_libraries(BionicSX2 PRIVATE ${CUBEB_LIB})
endif()
if(SOUNDTOUCH_LIB)
    target_link_libraries(BionicSX2 PRIVATE ${SOUNDTOUCH_LIB})
endif()
if(PNG_LIBRARY)
    target_link_libraries(BionicSX2 PRIVATE ${PNG_LIBRARY})
endif()
if(ZLIB_LIBRARY)
    target_link_libraries(BionicSX2 PRIVATE ${ZLIB_LIBRARY})
endif()

target_link_libraries(BionicSX2 PRIVATE "-lc++" "-liconv" "-lbsm")

# ── SwiftUI source files ──
set(SWIFT_SOURCES
    ${CMAKE_SOURCE_DIR}/ios/ui/BionicSX2App.swift
    ${CMAKE_SOURCE_DIR}/ios/ui/ContentView.swift
    ${CMAKE_SOURCE_DIR}/ios/ui/MetalViewController.swift
    ${CMAKE_SOURCE_DIR}/ios/ui/GameControllerManager.swift
)
target_sources(BionicSX2 PRIVATE ${SWIFT_SOURCES})
set_source_files_properties(${SWIFT_SOURCES} PROPERTIES LANGUAGE Swift)

# ── PCSX2Stubs.mm explicitly registered ──
target_sources(BionicSX2 PRIVATE
    ${CMAKE_SOURCE_DIR}/ios/platform/PCSX2Stubs.mm
)

# ── Compile features ──
target_compile_features(BionicSX2 PUBLIC cxx_std_20)
set_target_properties(BionicSX2 PROPERTIES
    CXX_STANDARD 20
    CXX_STANDARD_REQUIRED ON
    POSITION_INDEPENDENT_CODE ON
)

# ── Bundle settings ──
set_target_properties(BionicSX2 PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/ios/Info.plist"
    XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS "${CMAKE_SOURCE_DIR}/ios/entitlements/BionicSX2.entitlements"
    XCODE_ATTRIBUTE_MTL_ENABLE_DEBUG_INFO INCLUDE_SOURCE
    XCODE_ATTRIBUTE_CLANG_ENABLE_MODULES "YES"
    XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "NO"
)

target_include_directories(BionicSX2 PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/ios/platform
    ${CMAKE_SOURCE_DIR}/metal
)
