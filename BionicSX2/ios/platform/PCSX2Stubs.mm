// PORTED FROM: Stub file for iOS — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 13.7 (Category 1-9 fixes), Phase 0-F
// STATUS: NEW — prevents linker failures for subsystem stubs

#import <Foundation/Foundation.h>
#include "PrecompiledHeader.h"
#include "common/Assertions.h"
#include "common/HostSys.h"
#include "common/CocoaTools.h"
#include "common/Darwin/DarwinMisc.h"
#include "common/Threading.h"
#include "Config.h"
#include "Host.h"
#include "SaveState.h"
#include "Recording/InputRecording.h"
#include "DebugTools/Breakpoints.h"
#include "GSDumpReplayer.h"
#include "GameDatabase.h"
#include "GS/GS.h"
#include "GS/GSCapture.h"
#include "GS/GSDump.h"
#include "GS/GSPng.h"
#include "Host/AudioStream.h"
#include "ImGui/FullscreenUI.h"
#include "ImGui/ImGuiManager.h"
#include "Input/InputManager.h"

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

// CBreakPoints — now inline stubs in Breakpoints.h (iOS path)

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
class GSDevice;
class GSDeviceMTL;
std::vector<GSAdapterInfo> GetMetalAdapterList() { return {}; }
GSDevice* MakeGSDeviceMTL() { return nullptr; }

// AudioStream factory stubs
std::unique_ptr<AudioStream> AudioStream::CreateCubebAudioStream(u32, const AudioStreamParameters&, const char*, const char*, bool, Error*) { return nullptr; }
std::unique_ptr<AudioStream> AudioStream::CreateSDLAudioStream(u32, const AudioStreamParameters&, bool, Error*) { return nullptr; }
std::vector<std::pair<std::string, std::string>> AudioStream::GetCubebDriverNames() { return {}; }
std::vector<AudioStream::DeviceInfo> AudioStream::GetCubebOutputDevices(const char*) { return {}; }

// InputManager stubs (Audit Section 8.3 — replaced with GCController)
std::optional<u32> InputManager::ConvertHostKeyboardStringToCode(const std::string_view str) { return std::nullopt; }
std::optional<std::string> InputManager::ConvertHostKeyboardCodeToString(u32 code) { return std::nullopt; }
const char* InputManager::ConvertHostKeyboardCodeToIcon(u32 code) { return ""; }

// DebugInterface stubs — parseExpression now inline in Breakpoints.h iOS path

// DEV9 stubs (Category 8 — hardware not available on iOS)
u8 DEV9read8(u32 addr) { return 0; }
u16 DEV9read16(u32 addr) { return 0; }
u32 DEV9read32(u32 addr) { return 0; }
void DEV9write8(u32 addr, u8 value) {}
void DEV9write16(u32 addr, u16 value) {}
void DEV9write32(u32 addr, u32 value) {}
void DEV9readDMA8Mem(u32* pMem, int size) {}
void DEV9writeDMA8Mem(u32* pMem, int size) {}
void DEV9irqHandler() {}
void DEV9shutdown() {}

// CPU info stubs (common/HostSys.h — simplified for iOS)
u64 GetCPUTicks() { return 0; }
u64 GetTickFrequency() { return 1000000000; }
const CPUInfo& GetCPUInfo() { static CPUInfo info = {}; return info; }

u32 standardizeBreakpointAddress(u32 addr) { return addr; }

// GetValidDrive stub — optical drive not available on iOS
void GetValidDrive(std::string& drive) { drive.clear(); }

// ── AudioStream stubs ──
std::unique_ptr<AudioStream> AudioStream::CreateStream(AudioBackend, u32, const AudioStreamParameters&, const char*, const char*, bool, Error*) { return nullptr; }
std::unique_ptr<AudioStream> AudioStream::CreateNullStream(u32, u32) { return nullptr; }
void AudioStream::EmptyBuffer() {}
void AudioStream::SetNominalRate(float) {}
void AudioStream::SetOutputVolume(u32) {}
void AudioStream::SetStretchEnabled(bool) {}
bool AudioStream::WriteChunk(const float*) { return false; }
const char* AudioStream::GetBackendName(AudioBackend) { return ""; }
std::optional<AudioBackend> AudioStream::ParseBackendName(const char*) { return std::nullopt; }

// ── AudioStreamParameters stubs ──
void AudioStreamParameters::LoadSave(SettingsWrapper&, const char*) {}
bool AudioStreamParameters::operator==(const AudioStreamParameters& o) const { return true; }
bool AudioStreamParameters::operator!=(const AudioStreamParameters& o) const { return false; }

// ── Achievements stubs ──
void Achievements::ConfirmSystemReset() {}
bool Achievements::DisableHardcoreMode() { return false; }
void Achievements::FrameUpdate() {}
void Achievements::GameChanged(u32, u32) {}
void Achievements::IdleUpdate() {}
bool Achievements::Initialize() { return false; }
bool Achievements::IsActive() { return false; }
bool Achievements::IsHardcoreModeActive() { return false; }
bool Achievements::LoadState(std::span<const u8>) { return false; }
void Achievements::OnVMPaused(bool) {}
void Achievements::ResetClient() {}
void Achievements::ResetHardcoreMode(bool) {}
void Achievements::SaveState(SaveStateBase&) {}
void Achievements::Shutdown(bool) {}
void Achievements::UpdateSettings(const Pcsx2Config::AchievementsOptions&) {}

// ── FullscreenUI stubs ──
void FullscreenUI::CheckForConfigChanges(const Pcsx2Config&) {}
void FullscreenUI::GameChanged(std::string, std::string, std::string, u32, u32) {}
bool FullscreenUI::HasActiveWindow() { return false; }
void FullscreenUI::OnVMDestroyed() {}
void FullscreenUI::OnVMStarted() {}
void FullscreenUI::OpenAchievementsWindow() {}
void FullscreenUI::OpenLeaderboardsWindow() {}
void FullscreenUI::OpenPauseMenu() {}
void FullscreenUI::Render() {}
void FullscreenUI::ReportStateLoadError(const std::string&, std::optional<s32>, bool) {}
void FullscreenUI::ReportStateSaveError(const std::string&, std::optional<s32>) {}

// ── GSCapture stubs ──
bool GSCapture::BeginCapture(float, GSVector2i, float, std::string) { return false; }
void GSCapture::DeliverAudioPacket(const float*) {}
void GSCapture::DeliverVideoFrame(GSTexture*) {}
void GSCapture::EndCapture() {}
void GSCapture::Flush() {}
double GSCapture::GetElapsedTime() { return 0; }
void* GSCapture::GetEncoderThreadHandle() { return nullptr; }
std::string GSCapture::GetNextCaptureFileName() { return {}; }
u64 GSCapture::GetSize() { return 0; }
bool GSCapture::IsCapturing() { return false; }
bool GSCapture::IsCapturingVideo() { return false; }

// ── GSDumpBase stubs ──
bool GSDumpBase::CreateUncompressedDump(const std::string&, const std::string&, u32, u32, u32, const u32*, const freezeData&, const GSPrivRegSet*) { return false; }
bool GSDumpBase::CreateXzDump(const std::string&, const std::string&, u32, u32, u32, const u32*, const freezeData&, const GSPrivRegSet*) { return false; }
bool GSDumpBase::CreateZstDump(const std::string&, const std::string&, u32, u32, u32, const u32*, const freezeData&, const GSPrivRegSet*) { return false; }
bool GSDumpBase::ReadFIFO(u32) { return false; }
bool GSDumpBase::Transfer(int, const u8*, u64) { return false; }
bool GSDumpBase::VSync(int, bool, const GSPrivRegSet*) { return false; }
bool GSDumpReplayer::IsRunner() { return false; }

// ── GSPng stub ──
bool GSPng::Save(GSPng::Format, const std::string&, const u8*, int, int, int, int, bool) { return false; }

// ── SW renderer JIT stubs ──
GSDrawScanlineCodeGenerator::GSDrawScanlineCodeGenerator(uptr, void*, u64) {}
void GSDrawScanlineCodeGenerator::Generate() {}
GSSetupPrimCodeGenerator::GSSetupPrimCodeGenerator(uptr, void*, u64) {}
void GSSetupPrimCodeGenerator::Generate() {}

// ── FolderMemoryCard stubs ──
FolderMemoryCard::FolderMemoryCard() = default;
FolderMemoryCard::~FolderMemoryCard() = default;
void FolderMemoryCard::Close(bool) {}
bool FolderMemoryCard::IsFormatted() const { return false; }
bool FolderMemoryCard::Open(std::string, const McdOptions&, u32, bool, std::string, bool) { return false; }

// ── FolderMemoryCardAggregator stubs ──
FolderMemoryCardAggregator::FolderMemoryCardAggregator() = default;
void FolderMemoryCardAggregator::Close() {}
bool FolderMemoryCardAggregator::EraseBlock(u32, u32) { return false; }
u32 FolderMemoryCardAggregator::GetCRC(u32) { return 0; }
bool FolderMemoryCardAggregator::GetSizeInfo(u32, McdSizeInfo&) { return false; }
bool FolderMemoryCardAggregator::IsPSX(u32) { return false; }
bool FolderMemoryCardAggregator::IsPresent(u32) { return false; }
bool FolderMemoryCardAggregator::NextFrame(u32) { return false; }
bool FolderMemoryCardAggregator::Open() { return false; }
bool FolderMemoryCardAggregator::ReIndex(u32, bool, const std::string&) { return false; }
bool FolderMemoryCardAggregator::Read(u32, u8*, u32, int) { return false; }
bool FolderMemoryCardAggregator::Save(u32, const u8*, u32, int) { return false; }
void FolderMemoryCardAggregator::SetFiltering(bool) {}

// ── GameDatabaseSchema stubs ──
void GameDatabaseSchema::GameEntry::applyGSHardwareFixes(Pcsx2Config::GSOptions&) const {}
void GameDatabaseSchema::GameEntry::applyGameFixes(Pcsx2Config&, bool) const {}
const GameDatabaseSchema::GameEntry* GameDatabaseSchema::GameEntry::findPatch(u32) const { return nullptr; }
std::string GameDatabaseSchema::GameEntry::memcardFiltersAsString() const { return {}; }

// ── Host callbacks stubs ──
bool Host::AcquireRenderWindow(bool) { return false; }
void Host::BeginPresentFrame() {}
bool Host::CheckForSettingsChanges(const Pcsx2Config&) { return false; }
bool Host::IsFullscreen() { return false; }
bool Host::LoadSettings(SettingsInterface&, std::unique_lock<std::mutex>&) { return false; }
void Host::OnGameChanged(const std::string&, const std::string&, const std::string&, const std::string&, u32, u32) {}
void Host::OnInputDeviceConnected(std::string_view, std::string_view) {}
void Host::OnInputDeviceDisconnected(InputBindingKey, std::string_view) {}
void Host::OnPerformanceMetricsUpdated() {}
void Host::OnSaveStateLoaded(std::string_view, bool) {}
void Host::OnSaveStateLoading(std::string_view) {}
void Host::OnSaveStateSaved(std::string_view) {}
void Host::OnVMDestroyed() {}
void Host::OnVMPaused() {}
void Host::OnVMResumed() {}
void Host::OnVMStarted() {}
void Host::OnVMStarting() {}
void Host::PumpMessagesOnCPUThread() {}
void Host::ReleaseRenderWindow() {}
void Host::SetFullscreen(bool) {}
void Host::SetMouseLock(bool) {}
void Host::SetMouseMode(bool, bool) {}

// ── HostSys stubs ──
void HostSys::BeginCodeWrite() {}
void HostSys::EndCodeWrite() {}

// ── ImGui stubs ──
bool ImGui::Begin(const char*, bool*, int) { return false; }
bool ImGui::BeginChild(const char*, ImVec2, int, int) { return false; }
bool ImGui::BeginTable(const char*, int, int, ImVec2, float) { return false; }
void ImGui::End() {}
void ImGui::EndChild() {}
void ImGui::EndTable() {}
ImDrawList* ImGui::GetBackgroundDrawList() { return nullptr; }
ImGuiContext* ImGui::GetCurrentContext() { return nullptr; }
ImVec2 ImGui::GetCursorScreenPos() { return ImVec2(0,0); }
float ImGui::GetFontSize() { return 0; }
ImGuiIO& ImGui::GetIO() { static ImGuiIO io; return io; }
ImGuiPlatformIO& ImGui::GetPlatformIO() { static ImGuiPlatformIO pio; return pio; }
float ImGui::GetScrollY() { return 0; }
ImGuiStyle& ImGui::GetStyle() { static ImGuiStyle s; return s; }
ImDrawList* ImGui::GetWindowDrawList() { return nullptr; }
ImVec2 ImGui::GetWindowPos() { return ImVec2(0,0); }
void ImGui::Image(ImTextureID, ImVec2, ImVec2, ImVec2, ImVec2, ImVec4) {}
u32 ImGui::ColorConvertFloat4ToU32(ImVec4) { return 0; }
void ImGui::Indent(float) {}
void ImGui::ItemSize(ImVec2, float) {}
int ImGui::PlotLines(const char*, const float*, int, int, const char*, float, float, ImVec2, int) { return 0; }
void ImGui::PopFont() {}
void ImGui::PopStyleColor(int) {}
void ImGui::PopStyleVar(int) {}
void ImGui::PushFont(ImFont*, float) {}
void ImGui::PushStyleColor(int, ImVec4) {}
void ImGui::PushStyleVar(int, ImVec2) {}
void ImGui::PushStyleVar(int, float) {}
void ImGui::SetCursorPosX(float) {}
void ImGui::SetCursorPosY(float) {}
void ImGui::SetCursorScreenPos(ImVec2) {}
void ImGui::SetNextWindowPos(ImVec2, int, ImVec2) {}
void ImGui::SetNextWindowSize(ImVec2, int) {}
void ImGui::SetScrollY(float) {}
bool ImGui::TableNextColumn() { return false; }
void ImGui::TextUnformatted(const char*, const char*) {}
void ImGui::Unindent(float) {}
ImVec2 ImDrawList::AddLine(ImVec2, ImVec2, u32, float) { return ImVec2(0,0); }
ImVec2 ImDrawList::AddRectFilled(ImVec2, ImVec2, u32, float, int) { return ImVec2(0,0); }
ImVec2 ImDrawList::AddText(ImFont*, float, ImVec2, u32, const char*, const char*, float, const ImVec4*) { return ImVec2(0,0); }
float ImFont::CalcTextSizeA(float, float, float, const char*, const char*, const char**) { return 0; }

// ── ImGuiManager stubs ──
void ImGuiManager::ClearSoftwareCursor(u32) {}
ImFont* ImGuiManager::GetFixedFont() { return nullptr; }
float ImGuiManager::GetFontSizeStandard() { return 0; }
float ImGuiManager::GetGlobalScale() { return 1.0f; }
ImFont* ImGuiManager::GetOSDFont() { return nullptr; }
ImFont* ImGuiManager::GetStandardFont() { return nullptr; }
float ImGuiManager::GetWindowHeight() { return 0; }
float ImGuiManager::GetWindowWidth() { return 0; }
bool ImGuiManager::HasSoftwareCursor(u32) { return false; }
bool ImGuiManager::Initialize() { return false; }
void ImGuiManager::NewFrame() {}
void ImGuiManager::ProcessGenericInputEvent(GenericInputBinding, InputLayout, float) {}
void ImGuiManager::ProcessHostKeyEvent(InputBindingKey, float) {}
void ImGuiManager::ProcessPointerAxisEvent(InputBindingKey, float) {}
void ImGuiManager::ProcessPointerButtonEvent(InputBindingKey, float) {}
void ImGuiManager::ReloadFonts() {}
void ImGuiManager::RenderOSD() {}
void ImGuiManager::RequestScaleUpdate() {}
void ImGuiManager::SetSoftwareCursor(u32, std::string, float, u32) {}
void ImGuiManager::SetSoftwareCursorPosition(u32, float, float) {}
void ImGuiManager::Shutdown(bool) {}
bool ImGuiManager::SkipFrame() { return true; }
void ImGuiManager::UpdateMousePosition(float, float) {}
void ImGuiManager::WindowResized() {}
void* ImGuiFullscreen::LoadTexture(std::string_view) { return nullptr; }

// ── Threading stubs ──
void Threading::Sleep(int) {}
void Threading::SleepUntil(u64) {}
void ShortSpin() {}

// ── Common stubs ──
void Common::InhibitScreensaver(bool) {}
void AbortWithMessage(const char*) { std::abort(); }
u64 GetAvailablePhysicalMemory() { return 512ULL * 1024 * 1024; }
std::string GetOSVersionString() { return "iOS"; }
u64 GetPhysicalMemory() { return 512ULL * 1024 * 1024; }
std::unique_ptr<HTTPDownloader> HTTPDownloader::Create(std::string) { return nullptr; }

// ── RGBA8Image stubs ──
RGBA8Image::RGBA8Image() = default;
RGBA8Image::RGBA8Image(RGBA8Image&&) = default;
bool RGBA8Image::SaveToFile(const char*, u8) const { return false; }

// ── DEV9 stubs ──
void DEV9CheckChanges(const Pcsx2Config&) {}
void DEV9async(u32) {}
void DEV9close() {}
void DEV9init() {}
void DEV9open() {}

// ── CsoFileReader stub ──
CsoFileReader::CsoFileReader() = default;

// ── FileAccessHelper stub ──
FileAccessHelper::~FileAccessHelper() = default;

// ── cpuinfo C API stubs (for references from compiled PCSX2 objects) ──
extern "C" {
    void cpuinfo_initialize() {}
    const struct cpuinfo_core* cpuinfo_get_core(unsigned int) { return nullptr; }
    const struct cpuinfo_processor* cpuinfo_get_processor(unsigned int) { return nullptr; }
}

// ── Global variable stubs ──
alignas(16) u32 _SPIN_TIME_NS = 0;
CDVD_SourceType _CDVDapi_Disc = CDVD_SourceType::Iso;
ImGuiContext* _GImGui = nullptr;
u64 _GSDumpReplayerCpu = 0;
u32 g_host_hotkeys = 0;
