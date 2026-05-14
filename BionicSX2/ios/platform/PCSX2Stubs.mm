// PORTED FROM: Stub file for iOS — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 13.7 (Category 1-9 fixes), Phase 0-F
// STATUS: NEW — prevents linker failures for subsystem stubs

#import <Foundation/Foundation.h>
#include "PrecompiledHeader.h"
#include "common/Assertions.h"
#include "MetalRenderer.h"

// ── Category 1: SW Renderer JIT / x86 stubs ──
// Audit Section 0-B: GSDrawScanlineCodeGenerator/GSSetupPrimCodeGenerator excluded on iOS
void VifUnpackSSE_Init() {}
void vtlb_DynBackpatchLoadStore(uptr, u32, u32, u32, u8, u8, u8, bool, bool, bool) {}

// ── Category 5: ImGui stubs (not needed for BIOS-level rendering) ──
// Audit Section Phase 0-F Category 5

// ── Category 6: FullscreenUI stubs ──
// Audit Section Phase 0-F Category 6

// ── Category 8: Peripheral hardware stubs ──
// DEV9/smap (Audit Section 2.6 — network adapter, not needed on iOS)
u8 smap_read8(u32 addr) { return 0; }
u16 smap_read16(u32 addr) { return 0; }
u32 smap_read32(u32 addr) { return 0; }
void smap_write8(u32 addr, u8 value) {}
void smap_write16(u32 addr, u16 value) {}
void smap_write32(u32 addr, u32 value) {}
void smap_readDMA8Mem(u32* pMem, int size) {}
void smap_writeDMA8Mem(u32* pMem, int size) {}
void smap_async(u32 cycles) {}

// DEV9/FLASH
void FLASHinit() {}
u32 FLASHread32(u32 addr, int size) { return 0; }
void FLASHwrite32(u32 addr, u32 value, int size) {}

// DEV9/net
void InitNet() {}
void ReconfigureLiveNet(const Pcsx2Config& old_config) {}
void TermNet() {}

// USB/OHCI (Audit Section 2.6 — USB device emulation, not needed on iOS)
void ohci_frame_boundary(void* opaque) {}
int ohci_bus_start(void* ohci) { return 0; }
void ohci_bus_stop(void* ohci) {}

// USB/qemu
void usb_packet_set_state(void* p, int state) {}
void usb_handle_packet(void* dev, void* p) {}
void usb_packet_complete(void* dev, void* p) {}
void usb_ep_init(void* dev) {}
void usb_ep_reset(void* dev) {}
void usb_attach(void* port) {}
void usb_detach(void* port) {}
void usb_port_reset(void* port) {}
void usb_device_reset(void* dev) {}
void usb_wakeup(void* ep, unsigned int stream) {}
void usb_device_cancel_packet(void* dev, void* p) {}
int usb_desc_string(void* dev, int index, u8* dest, size_t len) { return 0; }
int usb_desc_handle_control(void* dev, void* p, int request, int value, int index, int length, u8* data) { return 0; }
int usb_desc_set_config(void* dev, int value) { return 0; }

// PGIF (Audit Section 2.3 — IOP processor)
void pgifInit() {}
void psxGPUw(int, u32) {}
u32 psxGPUr(int) { return 0; }
void psxDma2GpuR(u32 addr) {}
void psxDma2GpuW(u32 addr, u32 data) {}
void PGIFw(int, u32) {}
u32 PGIFr(int) { return 0; }
void PGIFwQword(u32 addr, void*) {}
void PGIFrQword(u32 addr, void*) {}

// FIFO / VIF / SIF (Audit Section 2.3)
void ReadFIFO_VIF1(void* out) {}
void WriteFIFO_VIF0(const void* value) {}
void WriteFIFO_VIF1(const void* value) {}
void WriteFIFO_GIF(const void* value) {}
bool ReadFifoSingleWord() { return false; }
void sifReset() {}
void SIF1Dma() {}
void dmaSIF1() {}
void dmaSIF2() {}
void EEsif1Interrupt() {}
void EEsif2Interrupt() {}
void sif1Interrupt() {}
void sif2Interrupt() {}

// VIF dynarec (Audit Section 2.3-F — disabled at compile time on iOS)
void dVifRelease(int idx) {}
void dVifReset(int idx) {}

// ── Category 9: Miscellaneous stubs ──

// CocoaTools (Audit Section 4.3 — macOS-only APIs replaced on iOS)
std::optional<std::string> CocoaTools::GetNonTranslocatedBundlePath() { return std::nullopt; }
std::optional<std::string> CocoaTools::GetResourcePath() {
    return [[[NSBundle mainBundle] resourcePath] UTF8String];
}

// DarwinMisc (Audit Section 5.3 — CPU class detection stubbed)
std::vector<DarwinMisc::CPUClass> DarwinMisc::GetCPUClasses() {
    return {};
}

// GameDatabase
const GameDatabaseSchema::GameEntry* GameDatabase::findGame(const std::string_view serial) {
    return nullptr;
}

// SaveState (Audit Section 2.1 — not needed on initial iOS port)
std::unique_ptr<SaveStateScreenshotData> SaveState_SaveScreenshot() { return nullptr; }
std::unique_ptr<ArchiveEntryList> SaveState_DownloadState(Error* error) { return nullptr; }
bool SaveState_ZipToDisk(std::unique_ptr<ArchiveEntryList> srclist, std::unique_ptr<SaveStateScreenshotData> screenshot, const char* filename, Error* error) { return false; }
bool SaveState_UnzipFromDisk(const std::string& filename, Error* error) { return false; }
void SaveState_ReportLoadErrorOSD(const std::string& message, std::optional<s32> slot, bool backup) {}
void SaveState_ReportSaveErrorOSD(const std::string& message, std::optional<s32> slot) {}

// InputRecording (Audit Section 2.1 — recording not needed on initial port)
bool InputRecording::create(const std::string& filename, const bool fromSaveState, const std::string& authorName) { return false; }
bool InputRecording::play(const std::string& path) { return false; }
void InputRecording::stop() {}
void InputRecording::handleControllerDataUpdate() {}
void InputRecording::saveControllerData(const PadData& data, const int port, const int slot) {}
std::optional<PadData> InputRecording::updateControllerData(const int port, const int slot) { return std::nullopt; }
void InputRecording::incFrameCounter() {}
u32 InputRecording::getFrameCounter() const { return 0; }
bool InputRecording::isActive() const { return false; }
void InputRecording::processRecordQueue() {}
void InputRecording::setStartingFrame(u32 startingFrame) {}
u32 InputRecording::getStartingFrame() { return 0; }
void InputRecording::handleExceededFrameCounter() {}
void InputRecording::handleReset() {}
void InputRecording::handleLoadingSavestate() {}
bool InputRecording::isTypeSavestate() const { return false; }
void InputRecording::adjustFrameCounterOnReRecord(u32 newFrameCounter) {}
InputRecordingControls& InputRecording::getControls() { static InputRecordingControls c; return c; }
const InputRecordingFile& InputRecording::getData() const { static InputRecordingFile f; return f; }
void InputRecording::InformGSThread() {}

// CBreakPoints (Audit Section 2.1 — debug tools not needed)
bool CBreakPoints::IsAddressBreakPoint(BreakPointCpu cpu, u32 addr) { return false; }
bool CBreakPoints::IsAddressBreakPoint(BreakPointCpu cpu, u32 addr, bool* enabled) { return false; }
bool CBreakPoints::IsTempBreakPoint(BreakPointCpu cpu, u32 addr) { return false; }
void CBreakPoints::AddBreakPoint(BreakPointCpu cpu, u32 addr, bool temp, bool enabled, bool stepping) {}
void CBreakPoints::RemoveBreakPoint(BreakPointCpu cpu, u32 addr) {}
void CBreakPoints::ClearAllBreakPoints() {}
void CBreakPoints::ClearTemporaryBreakPoints() {}
void CBreakPoints::AddMemCheck(BreakPointCpu cpu, u32 start, u32 end, MemCheckCondition cond, MemCheckResult result) {}
void CBreakPoints::RemoveMemCheck(BreakPointCpu cpu, u32 start, u32 end) {}
void CBreakPoints::ClearAllMemChecks() {}
void CBreakPoints::SetSkipFirst(BreakPointCpu cpu, u32 pc) {}
u32 CBreakPoints::CheckSkipFirst(BreakPointCpu cpu, u32 pc) { return 0; }
void CBreakPoints::ClearSkipFirst(BreakPointCpu cpu) {}
void CBreakPoints::CommitClearSkipFirst(BreakPointCpu cpu) {}
void CBreakPoints::Update(BreakPointCpu cpu, u32 addr) {}
void CBreakPoints::SetBreakpointTriggered(bool triggered, BreakPointCpu cpu) {}
bool CBreakPoints::GetBreakpointTriggered() { return false; }
bool CBreakPoints::GetCorePaused() { return false; }
void CBreakPoints::SetCorePaused(bool b) {}
size_t CBreakPoints::GetNumBreakpoints() { return 0; }

// GSDumpReplayer (Audit Section 2.4 — not needed)
bool GSDumpReplayer::IsReplayingDump() { return false; }
bool GSDumpReplayer::Initialize(const char* filename, Error* error) { return false; }
void GSDumpReplayer::Shutdown() {}
bool GSDumpReplayer::ChangeDump(const char* filename) { return false; }
std::string GSDumpReplayer::GetDumpSerial() { return ""; }
u32 GSDumpReplayer::GetDumpCRC() { return 0; }
u32 GSDumpReplayer::GetFrameNumber() { return 0; }
void GSDumpReplayer::RenderUI() {}

// BIOS / ShiftJIS / Misc
void ReadOSDConfigParames() {}
std::string ShiftJIS_ConvertString(const char* src) { return std::string(src); }

// Metal adapter list and device factory
std::vector<GSAdapterInfo> GetMetalAdapterList() { return {}; }
GSDevice* MakeGSDeviceMTL() { return new GSDeviceMTL(); }

// AudioStream factory stubs
std::unique_ptr<AudioStream> AudioStream::CreateCubebAudioStream(u32, const AudioStreamParameters&, const char*, const char*, bool, Error*) { return nullptr; }
std::unique_ptr<AudioStream> AudioStream::CreateSDLAudioStream(u32, const AudioStreamParameters&, bool, Error*) { return nullptr; }
std::vector<std::pair<std::string, std::string>> AudioStream::GetCubebDriverNames() { return {}; }
std::vector<AudioStream::DeviceInfo> AudioStream::GetCubebOutputDevices(const char*) { return {}; }

// InputManager stubs (Audit Section 8.3 — replaced with GCController)
std::optional<u32> InputManager::ConvertHostKeyboardStringToCode(const std::string_view str) { return std::nullopt; }
std::optional<std::string> InputManager::ConvertHostKeyboardCodeToString(u32 code) { return std::nullopt; }
const char* InputManager::ConvertHostKeyboardCodeToIcon(u32 code) { return ""; }

// DebugInterface stubs
bool DebugInterface::parseExpression(PostfixExpression& exp, u64& dest, std::string& error) { return false; }
u32 standardizeBreakpointAddress(u32 addr) { return addr; }
