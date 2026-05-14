// PORTED FROM: Host callback stubs — BionicSX2 iOS Port
// AUDIT REFERENCE: Section Phase 0-F Category 7
// STATUS: NEW — all Host:: callbacks required by the linker

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include "Host.h"
#include "common/ProgressCallback.h"
#include "common/SettingsInterface.h"

// Translation — pass-through (no localization on initial iOS port)
const char* Host::TranslateToCString(const std::string_view context, const std::string_view msg) {
    static std::string s;
    s = std::string(msg);
    return s.c_str();
}
std::string_view Host::TranslateToStringView(const std::string_view context, const std::string_view msg) { return msg; }
std::string Host::TranslateToString(const std::string_view context, const std::string_view msg) { return std::string(msg); }
std::string Host::TranslatePluralToString(const char* context, const char* msg, const char* disambiguation, int count) { return std::string(msg); }
void Host::ClearTranslationCache() {}

// OSD messages — no-op on iOS (no overlay in initial port)
void Host::AddOSDMessage(std::string message, float duration) {}
void Host::AddKeyedOSDMessage(std::string key, std::string message, float duration) {}
void Host::AddIconOSDMessage(std::string key, const char* icon, const std::string_view message, float duration) {}
void Host::RemoveKeyedOSDMessage(std::string key) {}
void Host::ClearOSDMessages() {}

// Async reporting — log to NSLog
void Host::ReportInfoAsync(const std::string_view title, const std::string_view message) {
    NSLog(@"[BionicSX2] Info: %.*s — %.*s", (int)title.size(), title.data(), (int)message.size(), message.data());
}
void Host::ReportFormattedInfoAsync(const std::string_view title, const char* format, ...) {
    va_list ap; va_start(ap, format);
    NSString* msg = [[NSString alloc] initWithFormat:[NSString stringWithUTF8String:format] arguments:ap];
    va_end(ap);
    NSLog(@"[BionicSX2] Info: %.*s — %@", (int)title.size(), title.data(), msg);
}
void Host::ReportErrorAsync(const std::string_view title, const std::string_view message) {
    NSLog(@"[BionicSX2] Error: %.*s — %.*s", (int)title.size(), title.data(), (int)message.size(), message.data());
}
void Host::ReportFormattedErrorAsync(const std::string_view title, const char* format, ...) {
    va_list ap; va_start(ap, format);
    NSString* msg = [[NSString alloc] initWithFormat:[NSString stringWithUTF8String:format] arguments:ap];
    va_end(ap);
    NSLog(@"[BionicSX2] Error: %.*s — %@", (int)title.size(), title.data(), msg);
}

// Mode queries
bool Host::InBatchMode() { return false; }
bool Host::InNoGUIMode() { return false; }

// System integration
void Host::OpenURL(const std::string_view url) {
    NSURL* nsurl = [NSURL URLWithString:[NSString stringWithUTF8String:std::string(url).c_str()]];
    if (nsurl) {
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            [UIApplication.sharedApplication openURL:nsurl options:@{} completionHandler:nil];
        });
    }
}
bool Host::CopyTextToClipboard(const std::string_view text) {
    NSString* str = [NSString stringWithUTF8String:std::string(text).c_str()];
    [UIPasteboard generalPasteboard].string = str;
    return true;
}
bool Host::RequestResetSettings(bool folders, bool core, bool controllers, bool hotkeys, bool ui) { return false; }
void Host::RequestResizeHostDisplay(s32 width, s32 height) {}

// Threading callbacks
void Host::RunOnCPUThread(std::function<void()> function, bool block) {
    if (block) function();
    else dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{ function(); });
}
void Host::RunOnGSThread(std::function<void()> function) {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{ function(); });
}

// Game list
void Host::RefreshGameListAsync(bool invalidate_cache) {}
void Host::CancelGameListRefresh() {}
void Host::RequestVMShutdown(bool allow_confirm, bool allow_save_state, bool default_save_state) {}

// HTTP user agent
std::string Host::GetHTTPUserAgent() { return "BionicSX2/0.1.0"; }

// Settings — thread-safe in-memory store
static std::mutex s_settings_mutex;
static std::unique_ptr<SettingsInterface> s_settings;

std::unique_lock<std::mutex> Host::GetSettingsLock() { return std::unique_lock<std::mutex>(s_settings_mutex); }
std::unique_lock<std::mutex> Host::GetSecretsSettingsLock() { return std::unique_lock<std::mutex>(s_settings_mutex); }
SettingsInterface* Host::GetSettingsInterface() { return s_settings.get(); }

std::string Host::GetBaseStringSettingValue(const char* section, const char* key, const char* default_value) { return default_value ? std::string(default_value) : std::string(); }
SmallString Host::GetBaseSmallStringSettingValue(const char* section, const char* key, const char* default_value) { SmallString s; if (default_value) s = default_value; return s; }
TinyString Host::GetBaseTinyStringSettingValue(const char* section, const char* key, const char* default_value) { TinyString s; if (default_value) s = default_value; return s; }
bool Host::GetBaseBoolSettingValue(const char* section, const char* key, bool default_value) { return default_value; }
int Host::GetBaseIntSettingValue(const char* section, const char* key, int default_value) { return default_value; }
uint Host::GetBaseUIntSettingValue(const char* section, const char* key, uint default_value) { return default_value; }
float Host::GetBaseFloatSettingValue(const char* section, const char* key, float default_value) { return default_value; }
double Host::GetBaseDoubleSettingValue(const char* section, const char* key, double default_value) { return default_value; }
std::vector<std::string> Host::GetBaseStringListSetting(const char* section, const char* key) { return {}; }

void Host::SetBaseBoolSettingValue(const char* section, const char* key, bool value) {}
void Host::SetBaseIntSettingValue(const char* section, const char* key, int value) {}
void Host::SetBaseUIntSettingValue(const char* section, const char* key, uint value) {}
void Host::SetBaseFloatSettingValue(const char* section, const char* key, float value) {}
void Host::SetBaseStringSettingValue(const char* section, const char* key, const char* value) {}
void Host::SetBaseStringListSettingValue(const char* section, const char* key, const std::vector<std::string>& values) {}
bool Host::AddBaseValueToStringList(const char* section, const char* key, const char* value) { return false; }
bool Host::RemoveBaseValueFromStringList(const char* section, const char* key, const char* value) { return false; }
bool Host::ContainsBaseSettingValue(const char* section, const char* key) { return false; }
void Host::RemoveBaseSettingValue(const char* section, const char* key) {}
void Host::CommitBaseSettingChanges() {}

std::string Host::GetStringSettingValue(const char* section, const char* key, const char* default_value) { return default_value ? std::string(default_value) : std::string(); }
SmallString Host::GetSmallStringSettingValue(const char* section, const char* key, const char* default_value) { SmallString s; if (default_value) s = default_value; return s; }
TinyString Host::GetTinyStringSettingValue(const char* section, const char* key, const char* default_value) { TinyString s; if (default_value) s = default_value; return s; }
bool Host::GetBoolSettingValue(const char* section, const char* key, bool default_value) { return default_value; }
int Host::GetIntSettingValue(const char* section, const char* key, int default_value) { return default_value; }
uint Host::GetUIntSettingValue(const char* section, const char* key, uint default_value) { return default_value; }
float Host::GetFloatSettingValue(const char* section, const char* key, float default_value) { return default_value; }
double Host::GetDoubleSettingValue(const char* section, const char* key, double default_value) { return default_value; }
std::vector<std::string> Host::GetStringListSetting(const char* section, const char* key) { return {}; }

// Internal settings layer
SettingsInterface* Host::Internal::GetBaseSettingsLayer() { return s_settings.get(); }
SettingsInterface* Host::Internal::GetSecretsSettingsLayer() { return nullptr; }
SettingsInterface* Host::Internal::GetGameSettingsLayer() { return nullptr; }
SettingsInterface* Host::Internal::GetInputSettingsLayer() { return nullptr; }
void Host::Internal::SetBaseSettingsLayer(SettingsInterface* sif) { s_settings.reset(sif); }
void Host::Internal::SetSecretsSettingsLayer(SettingsInterface* sif) {}
void Host::Internal::SetGameSettingsLayer(SettingsInterface* sif, std::unique_lock<std::mutex>& settings_lock) {}
void Host::Internal::SetInputSettingsLayer(SettingsInterface* sif, std::unique_lock<std::mutex>& settings_lock) {}
s32 Host::Internal::GetTranslatedStringImpl(const std::string_view context, const std::string_view msg, char* tbuf, size_t tbuf_space) {
    if (msg.size() < tbuf_space) { memcpy(tbuf, msg.data(), msg.size()); tbuf[msg.size()] = 0; return (s32)msg.size(); }
    return 0;
}
void Host::SetDefaultUISettings(SettingsInterface& si) {}
std::unique_ptr<ProgressCallback> Host::CreateHostProgressCallback() { return nullptr; }
int Host::LocaleSensitiveCompare(std::string_view lhs, std::string_view rhs) { return lhs.compare(rhs); }
