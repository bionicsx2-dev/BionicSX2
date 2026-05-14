# PORTED FROM: pcsx2/CMakeLists.txt — BionicSX2 iOS Port
# AUDIT REFERENCE: Section 10.1-10.2 (build system), Section 1.4-1.5,
#                  Section 10.3 (iOS-specific build settings)
# STATUS: YELLOW — iOS cross-compilation configuration

cmake_minimum_required(VERSION 3.20)
project(BionicSX2 C CXX OBJC OBJCXX)

# Audit Section 13.5: iOS cross-compilation toolchain
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_SOURCE_DIR}/cmake/ios.toolchain.cmake")

# Audit Section 1.2: ARM64 only — x86/ is N/A
set(CMAKE_OSX_ARCHITECTURES arm64)

# Audit Section 10.3: Deployment target iOS 15.0+ (Metal 2.3+)
set(CMAKE_OSX_DEPLOYMENT_TARGET 15.0)

# PCSX2 source tree root (for include paths)
set(PCSX2_ROOT "${CMAKE_SOURCE_DIR}/../pcsx2")

# Platform define for compile-time conditional (Audit Phase 0-C)
add_definitions(-DPCSX2_TARGET_IOS=1)

# ── Core emulator library (GREEN files from Audit Section 13.2) ──
add_subdirectory(src)

# ── iOS platform layer (Audit Section 13.3) ──
add_subdirectory(ios)

# ── Metal rendering backend (Audit Section 13.4) ──
add_subdirectory(metal)

# ── Final executable target ──
add_executable(BionicSX2 MACOSX_BUNDLE)

target_link_libraries(BionicSX2 PRIVATE
    pcsx2-core
    ios-platform
    metal-backend
)

# ── Link frameworks (all justified by audit) ──
find_library(METAL_LIBRARY Metal)
find_library(METALKIT_LIBRARY MetalKit)
find_library(AVFOUNDATION_LIBRARY AVFoundation)
find_library(GAMECONTROLLER_LIBRARY GameController)
find_library(FOUNDATION_LIBRARY Foundation)
find_library(UIKIT_LIBRARY UIKit)
find_library(QUARTZCORE_LIBRARY QuartzCore)

target_link_libraries(BionicSX2 PRIVATE
    ${METAL_LIBRARY}           # Audit Sec 3, 4  — Metal backend
    ${METALKIT_LIBRARY}        # Audit Sec 4.2   — MTKView convenience
    ${AVFOUNDATION_LIBRARY}    # Audit Sec 9.2   — Audio
    ${GAMECONTROLLER_LIBRARY}  # Audit Sec 8.3   — Input
    ${FOUNDATION_LIBRARY}      # Audit Sec 1.3   — Core Foundation
    ${UIKIT_LIBRARY}           # Audit Sec 4.3   — UIView/UIWindow
    ${QUARTZCORE_LIBRARY}      # Audit Sec 4.3   — CAMetalLayer
)

# ── SwiftUI source files (Audit Section 13.3) ──
set(SWIFT_SOURCES
    ${CMAKE_SOURCE_DIR}/ios/ui/BionicSX2App.swift
    ${CMAKE_SOURCE_DIR}/ios/ui/ContentView.swift
    ${CMAKE_SOURCE_DIR}/ios/ui/MetalViewController.swift
    ${CMAKE_SOURCE_DIR}/ios/ui/GameControllerManager.swift
)
target_sources(BionicSX2 PRIVATE ${SWIFT_SOURCES})
set_source_files_properties(${SWIFT_SOURCES} PROPERTIES LANGUAGE Swift)

# ── PCSX2Stubs.mm explicitly registered (Audit Phase 0-A) ──
target_sources(BionicSX2 PRIVATE
    ${CMAKE_SOURCE_DIR}/ios/platform/PCSX2Stubs.mm
)

# ── Compile features ──
target_compile_features(BionicSX2 PUBLIC cxx_std_17)
set_target_properties(BionicSX2 PROPERTIES
    CXX_STANDARD 17
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
