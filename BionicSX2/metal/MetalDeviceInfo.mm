// PORTED FROM: pcsx2/GS/Renderers/Metal/GSMTLDeviceInfo.mm — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 4.2 (device feature detection),
//                  Section 13.4 (remove AMD slow_color_compression heuristic)
// STATUS: GREEN — minimal changes

#import <Metal/Metal.h>
#include "MetalDeviceInfo.h"
#include "common/Console.h"

GSMTLDevice::GSMTLDevice(MRCOwned<id<MTLDevice>> device)
    : dev(std::move(device))
{
    id<MTLDevice> d = dev;
    features.unified_memory = true; // All iOS devices have unified memory (Audit Sec 4.3)
    features.texture_swizzle = [d supportsFamily:MTLGPUFamilyApple6];
    features.framebuffer_fetch = true; // Available on all Apple GPU iOS devices
    features.primid = false;
    // PORTED: slow_color_compression removed — AMD-specific, not on iOS (Audit Sec 13.4)
    features.slow_color_compression = false;
    features.has_fast_half = true;
    features.memoryless_textures = [d supportsFamily:MTLGPUFamilyApple4];
    features.depth_feedback = false;

    // Detect Metal version (Audit Sec 4.4 — all Metal versions available on iOS)
    if ([d supportsFamily:MTLGPUFamilyApple8])
        features.shader_version = MetalVersion::Metal23;
    else if ([d supportsFamily:MTLGPUFamilyApple7])
        features.shader_version = MetalVersion::Metal22;
    else if ([d supportsFamily:MTLGPUFamilyApple6])
        features.shader_version = MetalVersion::Metal21;
    else
        features.shader_version = MetalVersion::Metal20;

    features.max_texsize = static_cast<int>([d supportsFamily:MTLGPUFamilyApple3] ? 16384 : 8192);

    Console.WriteLn(Color_StrongGreen, "Metal Device: %s", [[d name] UTF8String]);
    Console.WriteLn(Color_StrongGreen, "Metal Version: %s", to_string(features.shader_version));
    Console.WriteLn(Color_StrongGreen, "Max Texture Size: %d", features.max_texsize);
}

const char* to_string(GSMTLDevice::MetalVersion ver)
{
    switch (ver)
    {
        case GSMTLDevice::MetalVersion::Metal20: return "Metal 2.0";
        case GSMTLDevice::MetalVersion::Metal21: return "Metal 2.1";
        case GSMTLDevice::MetalVersion::Metal22: return "Metal 2.2";
        case GSMTLDevice::MetalVersion::Metal23: return "Metal 2.3";
        default: return "Unknown";
    }
}
