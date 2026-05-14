#import <Foundation/Foundation.h>
#include "VMManager.h"
#include "GS/GS.h"
#include "Memory.h"
#include "R5900.h"
#include "Vif_Dynarec.h"
#include "CDVD/CDVD.h"

namespace iOSVMManager {

bool StartVM(const char* isoPath) {
    NSLog(@"[BionicSX2] iOSVMManager::StartVM starting");

    // Step 1: allocate emulated memory (MUST be first)
    if (!SysMemory::Allocate()) {
        NSLog(@"[BionicSX2] SysMemory::Allocate() failed");
        return false;
    }

    // Step 2: configure emulator
    EmuConfig.GS.Renderer = GSRendererType::Metal;

    // Belt-and-suspenders: disable all recompilers (nVif JIT, EE, VU, IOP)
    EmuConfig.Cpu.Recompiler.EnableEE  = false;
    EmuConfig.Cpu.Recompiler.EnableVU0 = false;
    EmuConfig.Cpu.Recompiler.EnableVU1 = false;
    EmuConfig.Cpu.Recompiler.EnableIOP = false;

    NSLog(@"[BionicSX2] Recompiler flags: EE=%d VU0=%d VU1=%d IOP=%d",
          EmuConfig.Cpu.Recompiler.EnableEE,
          EmuConfig.Cpu.Recompiler.EnableVU0,
          EmuConfig.Cpu.Recompiler.EnableVU1,
          EmuConfig.Cpu.Recompiler.EnableIOP);

    // Step 3: reset CPU state (triggers hwReset -> vif0Reset/vif1Reset)
    cpuReset();
    NSLog(@"[BionicSX2] cpuReset() completed");

    // Step 4: initialize GS with Metal backend
    if (!GSopen(nullptr, "Metal", 0)) {
        NSLog(@"[BionicSX2] GSopen failed");
        return false;
    }
    NSLog(@"[BionicSX2] GSopen (Metal) succeeded");

    // Step 5: load disc/ISO
    if (isoPath) {
        NSString* nsPath = [NSString stringWithUTF8String:isoPath];
        NSLog(@"[BionicSX2] Loading ISO: %@", nsPath);
        CDVDsys_SetFile(CDVD_SourceType::Iso, isoPath);
        CDVDsys_ChangeSource(CDVD_SourceType::Iso);
        NSLog(@"[BionicSX2] ISO loaded: %s", isoPath);
    }

    NSLog(@"[BionicSX2] iOSVMManager::StartVM completed successfully");
    return true;
}

void StopVM() {
    NSLog(@"[BionicSX2] iOSVMManager::StopVM");
    GSclose();
    SysMemory::Release();
}

} // namespace iOSVMManager

// C linkage wrappers for Swift access
void iOSVMManager_Init() {
    iOSVMManager::StartVM(nullptr);
}

void iOSVMManager_Shutdown() {
    iOSVMManager::StopVM();
}
