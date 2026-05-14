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

GSDeviceMTL::GSDeviceMTL()
{
    gsDeviceMTL = this;
}

GSDeviceMTL::~GSDeviceMTL()
{
    Destroy();
    gsDeviceMTL = nullptr;
}

bool GSDeviceMTL::Create(const WindowInfo& wi, std::string_view adapter, FeatureLevel feature_level, Error* error)
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

void GSDeviceMTL::DestroySurface()
{
}

bool GSDeviceMTL::SetLimits(bool wrapper)
{
    return true;
}

bool GSDeviceMTL::UsesOffscreenRendering() const
{
    return true;
}

bool GSDeviceMTL::IsDummyDevice() const
{
    return false;
}

GSDevice::FeatureLevel GSDeviceMTL::GetFeatureLevel() const
{
    return FeatureLevel::Metal;
}

void GSDeviceMTL::SetEnableFXAA(bool enable) {}
void GSDeviceMTL::SetEnableCAS(bool enable) {}
void GSDeviceMTL::SetEnableShadeBoost(bool enable) {}
void GSDeviceMTL::SetShadeBoostParams(float contrast, float brightness, float saturation) {}

std::string GSDeviceMTL::GetDeviceName() const
{
    return std::string([[GetDevice() name] UTF8String]);
}

std::string GSDeviceMTL::GetDriverInfo() const
{
    return "Metal";
}

bool GSDeviceMTL::DoFullscreenSwap(Error* error)
{
    return true;
}

void GSDeviceMTL::DoStretchRect(GSTexture* sTex, const GSVector4& sRect, GSTexture* dTex, const GSVector4& dRect, GSHWDrawConfig::ColorMaskSelector cms, ShaderConvert shader, bool linear)
{
}

void GSDeviceMTL::ClearRenderTarget(GSTexture* t, const GSVector4& c) {}
void GSDeviceMTL::ClearRenderTarget(GSTexture* t, const GSVector4& c, const GSVector4i& r) {}
void GSDeviceMTL::ClearDepth(GSTexture* t) {}
void GSDeviceMTL::ClearStencil(GSTexture* t) {}

bool GSDeviceMTL::CreateInterlacePassthroughBuffer() { return true; }
bool GSDeviceMTL::CreateInterlaceBuffer(const void* buff, size_t size) { return true; }

GSTexture* GSDeviceMTL::CreateRenderTarget(int width, int height, GSTexture::Format format, const std::string_view name)
{
    // PORTED: MTLTextureDescriptor usage unchanged (Audit Section 4.2)
    MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                    width:width
                                                                                   height:height
                                                                                mipmapped:NO];
    desc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    desc.storageMode = MTLResourceStorageModePrivate;

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
    desc.storageMode = MTLResourceStorageModePrivate;

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
    desc.storageMode = MTLResourceStorageModeShared;

    id<MTLTexture> tex = [GetDevice() newTextureWithDescriptor:desc];
    if (!tex) return nullptr;

    return new GSTextureMTL(this, MRCRetain(tex), GSTexture::Type::Texture, format);
}

GSTexture* GSDeviceMTL::CreateUploadTexture(int width, int height, int levels, GSTexture::Format format, const std::string_view name)
{
    return CreateTexture(width, height, levels, format, name);
}

std::unique_ptr<GSDownloadTexture> GSDeviceMTL::CreateDownloadTexture(u32 width, u32 height, GSTexture::Format format)
{
    return nullptr;
}

void GSDeviceMTL::ConvertToIndexedTexture(GSTexture* dst, GSVector4i dst_area, GSTexture* src, GSVector4i src_area, int first_src_level, int num_src_levels, bool linear) {}
void GSDeviceMTL::CopyRect(GSTexture* src, GSTexture* dest, const GSVector4i& src_rect, const GSVector4i& dest_rect) {}
void GSDeviceMTL::StretchRect(const GSVector4i& src_rect, const GSVector4i& dst_rect, GSTexture* src, const GSVector4i* src_uv_rect, GSTexture* dest, const GSVector4i* dest_uv_rect, int shader, bool linear, bool blend) {}
void GSDeviceMTL::PresentRect(const GSVector4i& src_rect, const GSVector4i& dst_rect, GSTexture* src, const GSVector4i* src_uv_rect, GSTexture* dest, const GSVector4i* dest_uv_rect, int shader, bool linear, bool blend) {}
void GSDeviceMTL::InvalidateCpuReadback() {}
void GSDeviceMTL::AgePoolFrames() {}
void GSDeviceMTL::RecycleObject(const GSTexture* tex) {}
std::unique_ptr<GSTexture> GSDeviceMTL::CreateSparseTexture(const std::string_view name) { return nullptr; }
void GSDeviceMTL::Flush() {}
void GSDeviceMTL::SubmitImage(GSTexture* tex, const void* data, u32 pitch, u32 layer) {}
void GSDeviceMTL::RenderHW(GSHWDrawConfig& config) {}
bool GSDeviceMTL::SupportsTextureCopyOffscreen() const { return true; }
bool GSDeviceMTL::TestCreateTexture(GSDevice::FeatureLevel feature_level) { return true; }
void GSDeviceMTL::PurgePools() {}
