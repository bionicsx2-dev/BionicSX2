# PORTED FROM: New file — BionicSX2 iOS Port
# AUDIT REFERENCE: Section 10.2 (CMake configuration for iOS),
#                  Section 13.5 (toolchain requirements)
# STATUS: NEW — iOS cross-compilation toolchain

# Audit Section 13.5: iOS cross-compilation toolchain
set(CMAKE_SYSTEM_NAME iOS)
set(CMAKE_OSX_ARCHITECTURES arm64)
set(CMAKE_OSX_DEPLOYMENT_TARGET 15.0)

# Audit Section 10.3: Use iphoneos SDK
set(CMAKE_OSX_SYSROOT iphoneos)

# Disable simulator builds
set(CMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH YES)

# C++ Standard Library
set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY "libc++")

# C++ Language Dialect: C++17
set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD "c++17")

# Enable Modules for Metal shader libraries
set(CMAKE_XCODE_ATTRIBUTE_CLANG_ENABLE_MODULES "YES")

# Objective-C++ Automatic Reference Counting: NO (MRCHelpers uses MRC)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "NO")

# Code signing identity for development builds
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "-")

# Audit Section 10.3: Metal compiler flags for .metal → .metallib compilation
set(CMAKE_XCODE_ATTRIBUTE_MTL_ENABLE_DEBUG_INFO "INCLUDE_SOURCE")

# Find UIKit (always available on iOS)
find_library(UIKIT_LIBRARY UIKit)
find_library(METAL_LIBRARY Metal)
find_library(AVFOUNDATION_LIBRARY AVFoundation)
find_library(GAMECONTROLLER_LIBRARY GameController)
find_library(QUARTZCORE_LIBRARY QuartzCore)
