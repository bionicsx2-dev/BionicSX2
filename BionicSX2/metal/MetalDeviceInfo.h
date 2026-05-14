// PORTED FROM: pcsx2/GS/Renderers/Metal/GSMTLDeviceInfo.h — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 4.2 (device feature detection)
// STATUS: GREEN — minimal changes

#pragma once

#ifndef __OBJC__
    #error "This header is for use with Objective-C++ only."
#endif

#ifdef __APPLE__

#include "common/MRCHelpers.h"
#include "common/Pcsx2Types.h"
#include "GS/Renderers/Common/GSShaderEnums.h"
#include <Metal/Metal.h>

struct GSMTLDevice
{
    enum class MetalVersion : u8
    {
        Metal20, ///< Metal 2.0 (macOS 10.13, iOS 11)
        Metal21, ///< Metal 2.1 (macOS 10.14, iOS 12)
        Metal22, ///< Metal 2.2 (macOS 10.15, iOS 13)
        Metal23, ///< Metal 2.3 (macOS 11, iOS 14)
    };

    struct Features
    {
        bool unified_memory         : 1;
        bool texture_swizzle        : 1;
        bool framebuffer_fetch      : 1;
        bool primid                 : 1;
        bool slow_color_compression : 1; ///< AMD-specific — not used on iOS
        bool has_fast_half          : 1;
        bool memoryless_textures    : 1;
        bool depth_feedback         : 1;
        MetalVersion shader_version;
        int max_texsize;
    };

    MRCOwned<id<MTLDevice>> dev;
    MRCOwned<id<MTLLibrary>> shaders;
    Features features;

    GSMTLDevice() = default;
    explicit GSMTLDevice(MRCOwned<id<MTLDevice>> dev);

    static u32 GetMaxTextureSize(id<MTLDevice> dev);

    bool IsOk() const { return dev && shaders; }
    void Reset()
    {
        dev = nullptr;
        shaders = nullptr;
    }
};

const char* to_string(GSMTLDevice::MetalVersion ver);

#endif // __APPLE__
