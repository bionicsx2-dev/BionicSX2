// PORTED FROM: VMManager.cpp — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 2.3-ADDENDUM (2.3-E, 2.3-F), Section 6.2, Section 12.2
// STATUS: NEW — iOS-specific VM init that prevents nVif HashBucket crash

#import <Foundation/Foundation.h>
#include "Config.h"
#include "Memory.h"
#include "VMManager.h"
#include "R5900.h"
#include "Vif_Dynarec.h"

// Audit Section 2.3-E: On macOS, the init chain is:
//   VMManager::StartVM() → SysMemory::Reset() → cpuReset() → hwReset() → vif0/1Reset() → resetNewVif(0/1)
// iOS must replicate this in correct order or nVif HashBucket remains uninitialized,
// causing SIGSEGV at Vif_HashBucket.h:68 on first VIF UNPACK command.

static bool s_initialized = false;

void iOSVMManager_Init()
{
    // Audit Section 2.3-F: Static init guard prevents re-entry crash loops
    if (s_initialized) {
        NSLog(@"[BionicSX2] iOSVMManager already initialized — skipping");
        return;
    }
    s_initialized = true;

    NSLog(@"[BionicSX2] iOSVMManager_Init starting");

    // ── Step 1: Configure EmuConfig BEFORE any reset calls ──
    // Audit Section 2.3-F: Force interpreter path — nVif dynarec disabled at compile time
    // via PCSX2_TARGET_IOS define in Vif_Dynarec.h. Set runtime config flags too.
    EmuConfig.Cpu.Recompiler.EnableEE  = false;  // Audit Sec 2.1 — interpreter only, no JIT
    EmuConfig.Cpu.Recompiler.EnableVU0 = false;  // Audit Sec 2.2 — VU interpreter paths
    EmuConfig.Cpu.Recompiler.EnableVU1 = false;  // Audit Sec 2.2 — VU interpreter paths
    EmuConfig.Cpu.Recompiler.EnableIOP = false;  // Audit Sec 2.3 — IOP interpreter only

    NSLog(@"[BionicSX2] Recompiler flags: EE=%d VU0=%d VU1=%d IOP=%d",
          EmuConfig.Cpu.Recompiler.EnableEE,
          EmuConfig.Cpu.Recompiler.EnableVU0,
          EmuConfig.Cpu.Recompiler.EnableVU1,
          EmuConfig.Cpu.Recompiler.EnableIOP);

    // ── Step 2: Allocate emulated memory before CPU init ──
    // Audit Section 2.3-E: SysMemory::Reset() must be called BEFORE cpuReset()
    // On macOS this happens at VMManager::StartVM():1525, before cpuReset():1526.
    // Without this, recWritePtr remains nullptr (BSS zero-init).
    if (!SysMemory::Reset()) {
        NSLog(@"[BionicSX2] CRITICAL: SysMemory::Reset() failed");
        return;
    }
    NSLog(@"[BionicSX2] SysMemory::Reset() succeeded");

    // ── Step 3: Initialize CPU and hardware ──
    // Audit Section 2.3-E: cpuReset() calls hwReset() which calls vif0Reset/vif1Reset
    // which calls resetNewVif(0/1). With newVifDynaRec=0, resetNewVif skips dVifReset()
    // and only initializes buffer/bSize/idx fields safely.
    cpuReset();
    NSLog(@"[BionicSX2] cpuReset() completed");

    NSLog(@"[BionicSX2] iOSVMManager_Init completed successfully");
}

void iOSVMManager_Shutdown()
{
    NSLog(@"[BionicSX2] iOSVMManager_Shutdown");
    s_initialized = false;
}
