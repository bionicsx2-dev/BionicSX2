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

} // namespace std

namespace std
{
template <>
struct hash<PipelineSelectorMTL>
{
    std::size_t operator()(const PipelineSelectorMTL& s) const noexcept
    {
        return HashMulti(s.ps.full, s.extras.fullkey, s.vs.full);
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
    bool SetLimits(bool wrapper) override;
    bool Create(const WindowInfo& wi, std::string_view adapter, FeatureLevel feature_level, Error* error) override;
    bool UsesOffscreenRendering() const override;
    bool IsDummyDevice() const override;
    FeatureLevel GetFeatureLevel() const override;
    void Destroy() override;
    void DestroySurface() override;
    void SetEnableFXAA(bool enable) override;
    void SetEnableCAS(bool enable) override;
    void SetEnableShadeBoost(bool enable) override;
    void SetShadeBoostParams(float contrast, float brightness, float saturation) override;
    std::string GetDeviceName() const override;
    std::string GetDriverInfo() const override;
    bool DoFullscreenSwap(Error* error) override;
    bool DoStretchRect(const GSVector4i& src_rect, const GSVector4i& dst_rect, GSTexture* src, GSTexture* dest, bool linear) override;
    void ClearRenderTarget(GSTexture* t, const GSVector4& c) override;
    void ClearRenderTarget(GSTexture* t, const GSVector4& c, const GSVector4i& r) override;
    void ClearDepth(GSTexture* t) override;
    void ClearStencil(GSTexture* t) override;
    bool CreateInterlacePassthroughBuffer() override;
    bool CreateInterlaceBuffer(const void* buff, size_t size) override;
    GSTexture* CreateRenderTarget(int width, int height, GSTexture::Format format, const std::string_view name) override;
    GSTexture* CreateDepthStencil(int width, int height, GSTexture::Format format, const std::string_view name) override;
    GSTexture* CreateTexture(int width, int height, int levels, GSTexture::Format format, const std::string_view name) override;
    GSTexture* CreateUploadTexture(int width, int height, int levels, GSTexture::Format format, const std::string_view name) override;
    std::unique_ptr<GSDownloadTexture> CreateDownloadTexture(u32 width, u32 height, GSTexture::Format format) override;
    void ConvertToIndexedTexture(GSTexture* dst, GSVector4i dst_area, GSTexture* src, GSVector4i src_area, int first_src_level, int num_src_levels, bool linear) override;
    void CopyRect(GSTexture* src, GSTexture* dest, const GSVector4i& src_rect, const GSVector4i& dest_rect) override;
    void StretchRect(const GSVector4i& src_rect, const GSVector4i& dst_rect, GSTexture* src, const GSVector4i* src_uv_rect, GSTexture* dest, const GSVector4i* dest_uv_rect, int shader, bool linear, bool blend) override;
    void PresentRect(const GSVector4i& src_rect, const GSVector4i& dst_rect, GSTexture* src, const GSVector4i* src_uv_rect, GSTexture* dest, const GSVector4i* dest_uv_rect, int shader, bool linear, bool blend) override;
    void InvalidateCpuReadback() override;
    void AgePoolFrames() override;
    void RecycleObject(const GSTexture* tex) override;
    std::unique_ptr<GSTexture> CreateSparseTexture(const std::string_view name) override;
    void Flush() override;
    void SubmitImage(GSTexture* tex, const void* data, u32 pitch, u32 layer) override;
    void RenderHW(GSHWDrawConfig& config) override;
    bool SupportsTextureCopyOffscreen() const override;
    bool TestCreateTexture(GSDevice::FeatureLevel feature_level) override;
    void PurgePools() override;
};

extern GSDeviceMTL* gsDeviceMTL;

GSDevice* MakeGSDeviceMTL();
std::vector<GSAdapterInfo> GetMetalAdapterList();

#endif // __APPLE__
