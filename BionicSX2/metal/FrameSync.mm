// PORTED FROM: GSDeviceMTL.mm (frame sync logic extracted) — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 4.2 (MTLFence, MTLCommandBuffer completion handlers,
//                  ReadbackSpinManager)
// STATUS: NEW — split from GSDeviceMTL.mm for iOS clarity

#import <Metal/Metal.h>
#include "common/ReadbackSpinManager.h"
#include "MetalRenderer.h"

// Frame synchronization using MTLFence and MTLCommandBuffer completion handlers
// Audit Section 4.2: MTLFence is available on iOS Metal

class FrameSync
{
public:
    FrameSync(id<MTLDevice> device)
        : m_fence(MRCTransfer([device newFence]))
    {
    }

    ~FrameSync() = default;

    void WaitForGPU()
    {
        if (m_last_command_buffer)
        {
            [m_last_command_buffer waitUntilCompleted];
            m_last_command_buffer = nil;
        }
    }

    void SetCommandBuffer(id<MTLCommandBuffer> cmdbuf)
    {
        m_last_command_buffer = cmdbuf;
    }

    id<MTLFence> GetFence() { return m_fence; }

private:
    MRCOwned<id<MTLFence>> m_fence;
    id<MTLCommandBuffer> m_last_command_buffer = nil;
};

// ReadbackSpinManager for GPU readback synchronization
// Audit Section 3.4: Used in GSDeviceMTL for draw ID tracking
// ReadbackSpinManager implementation from common/ReadbackSpinManager.cpp
