// PORTED FROM: pcsx2/GS/Renderers/Metal/GSTextureMTL.mm — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 3.5 (MTLResourceStorageModeShared works on iOS Apple Silicon)
// STATUS: GREEN — zero platform changes required

#import <Metal/Metal.h>
#include "MetalTexture.h"
#include "MetalRenderer.h"

GSTextureMTL::GSTextureMTL(GSDeviceMTL* dev, MRCOwned<id<MTLTexture>> texture, Type type, Format format)
    : GSTexture(type, format)
    , m_dev(dev)
    , m_texture(std::move(texture))
{
    m_size.x = [m_texture width];
    m_size.y = [m_texture height];
    m_native_handle = (void*)m_texture.Get();
}

GSTextureMTL::~GSTextureMTL()
{
}

void* GSTextureMTL::GetNativeHandle() const
{
    return (void*)m_texture.Get();
}

bool GSTextureMTL::Update(const GSVector4i& r, const void* data, int pitch, int layer)
{
    id<MTLTexture> tex = m_texture;
    MTLRegion region = MTLRegionMake2D(r.x, r.y, r.width(), r.height());
    [tex replaceRegion:region mipmapLevel:0 slice:layer withBytes:data bytesPerRow:pitch bytesPerImage:0];
    return true;
}

bool GSTextureMTL::Map(GSMap& m, const GSVector4i* r, int layer)
{
    // Audit Section 3.5: MTLResourceStorageModeShared works on iOS Apple Silicon
    id<MTLTexture> tex = m_texture;
    NSInteger pitch = [tex bufferBytesPerRow];
    void* ptr = [tex contents];
    if (!ptr) return false;

    m.bits = static_cast<u8*>(ptr);
    m.pitch = static_cast<u32>(pitch);
    return true;
}

void* GSTextureMTL::MapWithPitch(const GSVector4i& r, int pitch, int layer)
{
    id<MTLTexture> tex = m_texture;
    return [tex contents];
}

void GSTextureMTL::Unmap()
{
    // No-op for shared memory textures
}

void GSTextureMTL::GenerateMipmap()
{
    if (m_has_mipmaps) return;
    id<MTLTexture> tex = m_texture;
    if ([tex mipmapLevelCount] > 1)
    {
        id<MTLCommandBuffer> cmdbuf = [[GetDevice() newCommandQueue] commandBuffer];
        id<MTLBlitCommandEncoder> blit = [cmdbuf blitCommandEncoder];
        [blit generateMipmapsForTexture:tex];
        [blit endEncoding];
        [cmdbuf commit];
        m_has_mipmaps = true;
    }
}

#ifdef PCSX2_DEVBUILD
void GSTextureMTL::SetDebugName(std::string_view name)
{
    if (@available(iOS 16.0, *)) {
        [m_texture setLabel:[NSString stringWithUTF8String:std::string(name).c_str()]];
    }
}
#endif
