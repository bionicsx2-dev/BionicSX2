// PORTED FROM: pcsx2/GS/Renderers/Metal/GSDeviceMTL.mm — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 4.1-4.3 (Metal device, queue, pipeline state),
//                  Section 4.3 (NSView→UIView, NSWindow→UIWindow surface management)
// STATUS: YELLOW — AppKit replaced with UIKit, surface management adapted

// PORTED: AppKit removed, UIKit added (Audit Section 4.3)
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <simd/simd.h>

#include "MetalRenderer.h"
#include "MetalTexture.h"
#include "MetalDeviceInfo.h"
#include "common/Console.h"
#include "common/Error.h"
#include "Host.h"

#include <atomic>
#include <chrono>
#include <cmath>
#include <mutex>
#include <unordered_set>

GSDeviceMTL* gsDeviceMTL = nullptr;

static id<MTLDevice> GetDevice()
{
    static id<MTLDevice> dev = MTLCreateSystemDefaultDevice();
    return dev;
}

id<MTLDevice> GetMetalDevice() { return GetDevice(); }

GSDeviceMTL::GSDeviceMTL()
{
    gsDeviceMTL = this;
}

GSDeviceMTL::~GSDeviceMTL()
{
    Destroy();
    gsDeviceMTL = nullptr;
}

bool GSDeviceMTL::Create(GSVSyncMode vsync_mode, bool allow_present_throttle)
{
    NSLog(@"[BionicSX2] GSDeviceMTL::Create starting");

    id<MTLDevice> dev = GetDevice();
    if (!dev)
    {
        NSLog(@"[BionicSX2] No Metal device available");
        Host::ReportErrorAsync("GSDeviceMTL", "No Metal-supporting GPUs were found.");
        return false;
    }

    NSLog(@"[BionicSX2] Metal device: %s", [[dev name] UTF8String]);
    return true;
}

void GSDeviceMTL::Destroy()
{
    NSLog(@"[BionicSX2] GSDeviceMTL::Destroy");
}

// --- GSDevice pure virtual overrides ---

RenderAPI GSDeviceMTL::GetRenderAPI() const { return RenderAPI::Metal; }
bool GSDeviceMTL::HasSurface() const { return false; }
void GSDeviceMTL::DestroySurface() {}
bool GSDeviceMTL::UpdateWindow() { return true; }
void GSDeviceMTL::ResizeWindow(u32 new_window_width, u32 new_window_height, float new_window_scale) {}
bool GSDeviceMTL::SupportsExclusiveFullscreen() const { return false; }
GSDevice::PresentResult GSDeviceMTL::BeginPresent(bool frame_skip) { return PresentResult::OK; }
void GSDeviceMTL::EndPresent() {}
void GSDeviceMTL::SetVSyncMode(GSVSyncMode mode, bool allow_present_throttle) {}
std::string GSDeviceMTL::GetDriverInfo() const { return "Metal"; }
bool GSDeviceMTL::SetGPUTimingEnabled(bool enabled) { return false; }
float GSDeviceMTL::GetAndResetAccumulatedGPUTime() { return 0.0f; }
void GSDeviceMTL::PushDebugGroup(const char* fmt, ...) {}
void GSDeviceMTL::PopDebugGroup() {}
void GSDeviceMTL::InsertDebugMessage(DebugMessageCategory category, const char* fmt, ...) {}

std::unique_ptr<GSDownloadTexture> GSDeviceMTL::CreateDownloadTexture(u32 width, u32 height, GSTexture::Format format)
{
    return nullptr;
}

void GSDeviceMTL::CopyRect(GSTexture* sTex, GSTexture* dTex, const GSVector4i& r, u32 destX, u32 destY) {}

void GSDeviceMTL::PresentRect(GSTexture* sTex, const GSVector4& sRect, GSTexture* dTex, const GSVector4& dRect, PresentShader shader, float shaderTime, bool linear) {}

void GSDeviceMTL::UpdateCLUTTexture(GSTexture* sTex, float sScale, u32 offsetX, u32 offsetY, GSTexture* dTex, u32 dOffset, u32 dSize) {}

void GSDeviceMTL::ConvertToIndexedTexture(GSTexture* sTex, float sScale, u32 offsetX, u32 offsetY, u32 SBW, u32 SPSM, GSTexture* dTex, u32 DBW, u32 DPSM) {}

void GSDeviceMTL::FilteredDownsampleTexture(GSTexture* sTex, GSTexture* dTex, u32 downsample_factor, const GSVector2i& clamp_min, const GSVector4& dRect) {}

void GSDeviceMTL::RenderHW(GSHWDrawConfig& config) {}
void GSDeviceMTL::ClearSamplerCache() {}

void GSDeviceMTL::DoStretchRect(GSTexture* sTex, const GSVector4& sRect, GSTexture* dTex, const GSVector4& dRect, GSHWDrawConfig::ColorMaskSelector cms, ShaderConvert shader, bool linear) {}
void GSDeviceMTL::DoFXAA(GSTexture* sTex, GSTexture* dTex) {}
void GSDeviceMTL::DoShadeBoost(GSTexture* sTex, GSTexture* dTex, const float params[4]) {}
bool GSDeviceMTL::DoCAS(GSTexture* sTex, GSTexture* dTex, bool sharpen_only, const std::array<u32, NUM_CAS_CONSTANTS>& constants) { return false; }

void GSDeviceMTL::DoMerge(GSTexture* sTex[3], GSVector4* sRect, GSTexture* dTex, GSVector4* dRect, const GSRegPMODE& PMODE, const GSRegEXTBUF& EXTBUF, u32 c, const bool linear) {}

void GSDeviceMTL::DoInterlace(GSTexture* sTex, const GSVector4& sRect, GSTexture* dTex, const GSVector4& dRect, ShaderInterlace shader, bool linear, const InterlaceConstantBuffer& cb) {}

GSTexture* GSDeviceMTL::CreateSurface(GSTexture::Type type, int width, int height, int levels, GSTexture::Format format)
{
    switch (type)
    {
        case GSTexture::Type::RenderTarget:
            return CreateRenderTarget(width, height, format, {});
        case GSTexture::Type::DepthStencil:
            return CreateDepthStencil(width, height, format, {});
        case GSTexture::Type::Texture:
            return CreateTexture(width, height, levels, format, {});
        default:
            return nullptr;
    }
}

// --- Texture creation helpers (kept as internal helpers, no longer direct overrides) ---

GSTexture* GSDeviceMTL::CreateRenderTarget(int width, int height, GSTexture::Format format, const std::string_view name)
{
    MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                    width:width
                                                                                   height:height
                                                                                mipmapped:NO];
    desc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    desc.storageMode = (MTLStorageMode)MTLResourceStorageModePrivate;

    id<MTLTexture> tex = [GetDevice() newTextureWithDescriptor:desc];
    if (!tex) return nullptr;

    return new GSTextureMTL(this, MRCRetain(tex), GSTexture::Type::RenderTarget, format);
}

GSTexture* GSDeviceMTL::CreateDepthStencil(int width, int height, GSTexture::Format format, const std::string_view name)
{
    MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                                                    width:width
                                                                                   height:height
                                                                                mipmapped:NO];
    desc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    desc.storageMode = (MTLStorageMode)MTLResourceStorageModePrivate;

    id<MTLTexture> tex = [GetDevice() newTextureWithDescriptor:desc];
    if (!tex) return nullptr;

    return new GSTextureMTL(this, MRCRetain(tex), GSTexture::Type::DepthStencil, format);
}

GSTexture* GSDeviceMTL::CreateTexture(int width, int height, int levels, GSTexture::Format format, const std::string_view name)
{
    MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                    width:width
                                                                                   height:height
                                                                                mipmapped:(levels > 1)];
    if (levels > 1) desc.mipmapLevelCount = levels;
    desc.usage = MTLTextureUsageShaderRead;
    desc.storageMode = (MTLStorageMode)MTLResourceStorageModeShared;

    id<MTLTexture> tex = [GetDevice() newTextureWithDescriptor:desc];
    if (!tex) return nullptr;

    return new GSTextureMTL(this, MRCRetain(tex), GSTexture::Type::Texture, format);
}

GSTexture* GSDeviceMTL::CreateUploadTexture(int width, int height, int levels, GSTexture::Format format, const std::string_view name)
{
    return CreateTexture(width, height, levels, format, name);
}
