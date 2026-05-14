// PCSX2Stubs.mm — iOS stubs, auto-corrected against actual headers

#include "PrecompiledHeader.h"
#include "GS/GSCapture.h"
#include "GS/GSDump.h"
#include "GS/Renderers/SW/GSDrawScanline.h"
#include "ImGui/FullscreenUI.h"
#include "ImGui/ImGuiManager.h"
#include "Achievements.h"
#include "Host.h"

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
std::unique_ptr<GSDumpBase> GSDumpBase::CreateUncompressedDump(const std::string& fn, u32 crc, const std::string& serial, const GSPrivRegSet* regs, bool comp) { return nullptr; }
std::unique_ptr<GSDumpBase> GSDumpBase::CreateXzDump(const std::string& fn, u32 crc, const std::string& serial, const GSPrivRegSet* regs, bool comp) { return nullptr; }
std::unique_ptr<GSDumpBase> GSDumpBase::CreateZstDump(const std::string& fn, u32 crc, const std::string& serial, const GSPrivRegSet* regs, bool comp) { return nullptr; }

// SW Renderer code generators
GSDrawScanlineCodeGenerator::GSDrawScanlineCodeGenerator(u64 key, void* code, size_t maxsize) {}
void GSDrawScanlineCodeGenerator::Generate() {}
GSSetupPrimCodeGenerator::GSSetupPrimCodeGenerator(u64 key, void* code, size_t maxsize) {}
void GSSetupPrimCodeGenerator::Generate() {}

// FullscreenUI
bool FullscreenUI::OpenAchievementsWindow() { return false; }
bool FullscreenUI::OpenLeaderboardsWindow() { return false; }
void FullscreenUI::Render(float) {}

// ImGuiManager stubs
void ImGuiManager::Initialize() {}
void ImGuiManager::WindowResized() {}
void ImGuiManager::ReloadFonts() {}
ImFont* ImGuiManager::GetOSDFont() { return nullptr; }
ImFont* ImGuiManager::GetFixedFont() { return nullptr; }
float ImGuiManager::GetGlobalScale() { return 1.0f; }
float ImGuiManager::GetWindowWidth() { return 0.0f; }

// Achievements
bool Achievements::ConfirmSystemReset() { return true; }
void Achievements::DisableHardcoreMode() {}
void Achievements::FrameUpdate() {}
void Achievements::GameChanged(u32 crc, const std::string& serial, const std::string& path) {}
void Achievements::IdleUpdate() {}
bool Achievements::Initialize() { return false; }
bool Achievements::IsActive() { return false; }
bool Achievements::IsHardcoreModeActive() { return false; }
void Achievements::LoadState(const u8* data, u32 length) {}
void Achievements::OnVMPaused() {}
void Achievements::ResetClient() {}
void Achievements::ResetHardcoreMode() {}
void Achievements::SaveState(u8* data, u32 length) {}
void Achievements::Shutdown() {}
void Achievements::UpdateSettings(const Pcsx2Config::AchievementsOptions& old) {}
