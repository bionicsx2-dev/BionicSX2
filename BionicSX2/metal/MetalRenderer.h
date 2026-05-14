// PORTED FROM: pcsx2/GS/Renderers/Metal/GSDeviceMTL.h — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 4.1-4.3 (Metal backend portability)
// STATUS: YELLOW — removed NSView/AppKit references, replaced with UIView/UIKit

#pragma once

#include "GS/Renderers/Common/GSDevice.h"

#ifndef __OBJC__
    #error "This header is for use with Objective-C++ only."
#endif

#ifdef __APPLE__

#include "common/HashCombine.h"
#include "common/MRCHelpers.h"
#include "common/ReadbackSpinManager.h"
#include "GS/GS.h"
#include "MetalDeviceInfo.h"
#include "MetalSharedHeader.h"

// PORTED: AppKit/AppKit.h removed, UIKit/UIKit.h added (Audit Section 4.3)
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include <atomic>
#include <memory>
#include <mutex>
#include <vector>
#include <unordered_map>
#include <utility>

struct PipelineSelectorExtrasMTL
{
    union
    {
        struct
        {
            GSTexture::Format rt : 4;
            u8 writemask : 4;
            GSDevice::BlendFactor src_factor : 4;
            GSDevice::BlendFactor dst_factor : 4;
            GSDevice::BlendFactor src_factor_alpha : 4;
            GSDevice::BlendFactor dst_factor_alpha : 4;
            GSDevice::BlendOp     blend_op : 2;
            bool blend_enable : 1;
            bool has_depth    : 1;
            bool has_stencil  : 1;
            bool has_rt1      : 1;
        };
        u32 fullkey;
    };

    PipelineSelectorExtrasMTL(): fullkey(0) {}
    PipelineSelectorExtrasMTL(GSHWDrawConfig::BlendState blend, GSTexture* rt, GSHWDrawConfig::ColorMaskSelector cms, bool has_depth, bool has_stencil, bool has_rt1)
        : fullkey(0)
    {
        this->rt = rt ? rt->GetFormat() : GSTexture::Format::Invalid;
        MTLColorWriteMask mask = MTLColorWriteMaskNone;
        if (cms.wr) mask |= MTLColorWriteMaskRed;
        if (cms.wg) mask |= MTLColorWriteMaskGreen;
        if (cms.wb) mask |= MTLColorWriteMaskBlue;
        if (cms.wa) mask |= MTLColorWriteMaskAlpha;
        this->writemask = mask;
        this->src_factor = static_cast<GSDevice::BlendFactor>(blend.src_factor);
        this->dst_factor = static_cast<GSDevice::BlendFactor>(blend.dst_factor);
        this->blend_op = static_cast<GSDevice::BlendOp>(blend.op);
        this->src_factor_alpha = static_cast<GSDevice::BlendFactor>(blend.src_factor_alpha);
        this->dst_factor_alpha = static_cast<GSDevice::BlendFactor>(blend.dst_factor_alpha);
        this->blend_enable = blend.enable;
        this->has_depth   = has_depth;
        this->has_stencil = has_stencil;
        this->has_rt1     = has_rt1;
    }
};

struct PipelineSelectorMTL
{
    GSHWDrawConfig::PSSelector ps;
    PipelineSelectorExtrasMTL extras;
    GSHWDrawConfig::VSSelector vs;
    u8 pad[7];

    PipelineSelectorMTL()
    {
        memset(this, 0, sizeof(*this));
    }
    bool operator==(const PipelineSelectorMTL& rhs) const
    {
        return std::memcmp(this, &rhs, sizeof(*this)) == 0;
    }
};

namespace std
{
template <>
struct hash<PipelineSelectorMTL>
{
    std::size_t operator()(const PipelineSelectorMTL& s) const noexcept
    {
        std::size_t h = 0;
        HashCombine(h, s.ps.key_lo);
        HashCombine(h, s.ps.key_hi);
        HashCombine(h, s.extras.fullkey);
        HashCombine(h, s.vs.key);
        return h;
    }
};
}

class GSDeviceMTL final : public GSDevice
{
public:
    GSDeviceMTL();
    ~GSDeviceMTL() override;

    static constexpr u32 MAX_TEX_STAGING_BUFFER_SIZE = 64 * 1024 * 1024;
    static constexpr u32 MAX_VERTEX_STAGING_BUFFER_SIZE = 64 * 1024 * 1024;
    static constexpr u32 NUM_COMMAND_BUFFERS = 16;

    // Inherited via GSDevice
    RenderAPI GetRenderAPI() const override;
    bool HasSurface() const override;
    void DestroySurface() override;
    bool UpdateWindow() override;
    void ResizeWindow(u32 new_window_width, u32 new_window_height, float new_window_scale) override;
    bool SupportsExclusiveFullscreen() const override;
    PresentResult BeginPresent(bool frame_skip) override;
    void EndPresent() override;
    void SetVSyncMode(GSVSyncMode mode, bool allow_present_throttle) override;
    std::string GetDriverInfo() const override;
    bool SetGPUTimingEnabled(bool enabled) override;
    float GetAndResetAccumulatedGPUTime() override;
    void PushDebugGroup(const char* fmt, ...) override;
    void PopDebugGroup() override;
    void InsertDebugMessage(DebugMessageCategory category, const char* fmt, ...) override;
    std::unique_ptr<GSDownloadTexture> CreateDownloadTexture(u32 width, u32 height, GSTexture::Format format) override;
    void CopyRect(GSTexture* sTex, GSTexture* dTex, const GSVector4i& r, u32 destX, u32 destY) override;
    void PresentRect(GSTexture* sTex, const GSVector4& sRect, GSTexture* dTex, const GSVector4& dRect, PresentShader shader, float shaderTime, bool linear) override;
    void UpdateCLUTTexture(GSTexture* sTex, float sScale, u32 offsetX, u32 offsetY, GSTexture* dTex, u32 dOffset, u32 dSize) override;
    void ConvertToIndexedTexture(GSTexture* sTex, float sScale, u32 offsetX, u32 offsetY, u32 SBW, u32 SPSM, GSTexture* dTex, u32 DBW, u32 DPSM) override;
    void FilteredDownsampleTexture(GSTexture* sTex, GSTexture* dTex, u32 downsample_factor, const GSVector2i& clamp_min, const GSVector4& dRect) override;
    void RenderHW(GSHWDrawConfig& config) override;
    void ClearSamplerCache() override;
    void DoStretchRect(GSTexture* sTex, const GSVector4& sRect, GSTexture* dTex, const GSVector4& dRect, GSHWDrawConfig::ColorMaskSelector cms, ShaderConvert shader, bool linear) override;
    void DoFXAA(GSTexture* sTex, GSTexture* dTex) override;
    void DoShadeBoost(GSTexture* sTex, GSTexture* dTex, const float params[4]) override;
    bool DoCAS(GSTexture* sTex, GSTexture* dTex, bool sharpen_only, const std::array<u32, NUM_CAS_CONSTANTS>& constants) override;
    void DoMerge(GSTexture* sTex[3], GSVector4* sRect, GSTexture* dTex, GSVector4* dRect, const GSRegPMODE& PMODE, const GSRegEXTBUF& EXTBUF, u32 c, const bool linear) override;
    void DoInterlace(GSTexture* sTex, const GSVector4& sRect, GSTexture* dTex, const GSVector4& dRect, ShaderInterlace shader, bool linear, const InterlaceConstantBuffer& cb) override;

    GSTexture* CreateSurface(GSTexture::Type type, int width, int height, int levels, GSTexture::Format format) override;

    bool Create(GSVSyncMode vsync_mode, bool allow_present_throttle) override;
    void Destroy() override;

    // Internal texture helpers (routed through CreateSurface, separate decl for .mm)
    GSTexture* CreateRenderTarget(int width, int height, GSTexture::Format format, const std::string_view name);
    GSTexture* CreateDepthStencil(int width, int height, GSTexture::Format format, const std::string_view name);
    GSTexture* CreateTexture(int width, int height, int levels, GSTexture::Format format, const std::string_view name);
    GSTexture* CreateUploadTexture(int width, int height, int levels, GSTexture::Format format, const std::string_view name);
};

extern GSDeviceMTL* gsDeviceMTL;
id<MTLDevice> GetMetalDevice();

GSDevice* MakeGSDeviceMTL();
std::vector<GSAdapterInfo> GetMetalAdapterList();

#endif // __APPLE__
