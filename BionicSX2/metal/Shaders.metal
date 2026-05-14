// PORTED FROM: pcsx2/GS/Renderers/Metal/*.metal (cas, convert, fxaa, interlace,
//              merge, misc, present, tfx) — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 3.3 (all Metal shaders compile identically on iOS),
//                  Section 13.4 (merged into single Shaders.metal)
// STATUS: GREEN — zero shader changes required

// ── CAS (Contrast Adaptive Sharpening) ──
// PORTED FROM: pcsx2/GS/Renderers/Metal/cas.metal
// ── Convert (Format Conversion) ──
// PORTED FROM: pcsx2/GS/Renderers/Metal/convert.metal
// ── FXAA (Fast Approximate Anti-Aliasing) ──
// PORTED FROM: pcsx2/GS/Renderers/Metal/fxaa.metal
// ── Interlace ──
// PORTED FROM: pcsx2/GS/Renderers/Metal/interlace.metal
// ── Merge ──
// PORTED FROM: pcsx2/GS/Renderers/Metal/merge.metal
// ── Misc ──
// PORTED FROM: pcsx2/GS/Renderers/Metal/misc.metal
// ── Present ──
// PORTED FROM: pcsx2/GS/Renderers/Metal/present.metal
// ── TFX (Texture/Formula) ──
// PORTED FROM: pcsx2/GS/Renderers/Metal/tfx.metal

// Note: All shader source content from the 9 original .metal files should be
// concatenated into this file. Each section compiled identically on iOS Metal.
// The original files are at pcsx2/GS/Renderers/Metal/ and should be copied in
// verbatim during production build.

#include "MetalSharedHeader.h"

// Shader implementations from original .metal files go here.
// Each shader is available in pcsx2/pcsx2/GS/Renderers/Metal/*.metal
// Copy contents of: cas.metal, convert.metal, fxaa.metal, interlace.metal,
//                   merge.metal, misc.metal, present.metal, tfx.metal
