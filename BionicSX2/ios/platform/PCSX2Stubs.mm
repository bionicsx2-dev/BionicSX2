#include "PrecompiledHeader.h"
#include "GS/GSCapture.h"
#include "GS/GSDump.h"
#include "ImGui/FullscreenUI.h"
#include "ImGui/ImGuiManager.h"
#include "Achievements.h"
#include "common/Threading.h"
#include "common/SaveState.h"
#include <span>

// GSCapture
bool GSCapture::BeginCapture(float fps, GSVector2i recommendedResolution, float aspect, std::string filename) { return false; }
bool GSCapture::DeliverVideoFrame(GSTexture* stex) { return false; }
void GSCapture::DeliverAudioPacket(const float* frames) {}
void GSCapture::EndCapture() {}
bool GSCapture::IsCapturing() { return false; }
bool GSCapture::IsCapturingVideo() { return false; }
bool GSCapture::IsCapturingAudio() { return false; }
TinyString GSCapture::GetElapsedTime() { return TinyString(); }
const Threading::ThreadHandle& GSCapture::GetEncoderThreadHandle() { static Threading::ThreadHandle h; return h; }
GSVector2i GSCapture::GetSize() { return GSVector2i(0, 0); }
std::string GSCapture::GetNextCaptureFileName() { return {}; }
void GSCapture::Flush() {}

// GSDumpBase
void GSDumpBase::ReadFIFO(u32 size) {}
void GSDumpBase::Transfer(int index, const u8* mem, size_t size) {}
std::unique_ptr<GSDumpBase> GSDumpBase::CreateUncompressedDump(const std::string& fn, const std::string& serial, u32 crc, u32 screenshot_width, u32 screenshot_height, const u32* screenshot_pixels, const freezeData fd, const GSPrivRegSet* regs) { return nullptr; }
std::unique_ptr<GSDumpBase> GSDumpBase::CreateXzDump(const std::string& fn, const std::string& serial, u32 crc, u32 screenshot_width, u32 screenshot_height, const u32* screenshot_pixels, const freezeData fd, const GSPrivRegSet* regs) { return nullptr; }
std::unique_ptr<GSDumpBase> GSDumpBase::CreateZstDump(const std::string& fn, const std::string& serial, u32 crc, u32 screenshot_width, u32 screenshot_height, const u32* screenshot_pixels, const freezeData fd, const GSPrivRegSet* regs) { return nullptr; }

// SW renderer code generators — no vixl dependency
struct GSDrawScanlineCodeGenerator {
    GSDrawScanlineCodeGenerator(u64, void*, size_t) {}
    void Generate() {}
};
struct GSSetupPrimCodeGenerator {
    GSSetupPrimCodeGenerator(u64, void*, size_t) {}
    void Generate() {}
};

// FullscreenUI
bool FullscreenUI::OpenAchievementsWindow() { return false; }
bool FullscreenUI::OpenLeaderboardsWindow() { return false; }
void FullscreenUI::Render() {}

// ImGuiManager
bool ImGuiManager::Initialize() { return false; }
void ImGuiManager::WindowResized() {}
void ImGuiManager::ReloadFonts() {}
ImFont* ImGuiManager::GetOSDFont() { return nullptr; }
ImFont* ImGuiManager::GetFixedFont() { return nullptr; }
float ImGuiManager::GetGlobalScale() { return 1.0f; }
float ImGuiManager::GetWindowWidth() { return 0.0f; }
float ImGuiManager::GetWindowHeight() { return 0.0f; }

// Achievements
bool Achievements::ConfirmSystemReset() { return true; }
void Achievements::DisableHardcoreMode() {}
void Achievements::FrameUpdate() {}
void Achievements::GameChanged(u32 disc_crc, u32 crc) {}
void Achievements::IdleUpdate() {}
bool Achievements::Initialize() { return false; }
bool Achievements::IsActive() { return false; }
bool Achievements::IsHardcoreModeActive() { return false; }
void Achievements::LoadState(std::span<const u8> data) {}
void Achievements::OnVMPaused(bool paused) {}
void Achievements::ResetClient() {}
bool Achievements::ResetHardcoreMode(bool is_booting) { return false; }
void Achievements::SaveState(SaveStateBase& writer) {}
bool Achievements::Shutdown(bool allow_cancel) { return true; }
void Achievements::UpdateSettings(const Pcsx2Config::AchievementsOptions& old) {}
