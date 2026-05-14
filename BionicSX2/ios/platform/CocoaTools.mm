// PORTED FROM: common/CocoaTools.mm — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 4.3 (surface management), Section 1.3 (platform-specific files)
// STATUS: YELLOW — NSView→UIView, NSWindow→UIWindow, AppKit→UIKit replacements

#if ! __has_feature(objc_arc)
    #error "Compile this with -fobjc-arc"
#endif

#include "CocoaTools.h"
#include "Console.h"
#include "HostSys.h"
#include "WindowInfo.h"
#include <mutex>

// PORTED: AppKit removed, UIKit added (Audit Section 4.3)
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>

// PORTED: CreateMetalLayer — NSView replaced with UIView (Audit Section 4.3)
bool CocoaTools::CreateMetalLayer(WindowInfo* wi)
{
    if (![NSThread isMainThread])
    {
        __block bool ret;
        dispatch_sync(dispatch_get_main_queue(), ^{ ret = CreateMetalLayer(wi); });
        return ret;
    }

    CAMetalLayer* layer = [CAMetalLayer layer];
    if (!layer)
    {
        Console.Error("Failed to create Metal layer.");
        return false;
    }

    // PORTED: NSView → UIView (Audit Section 4.3)
    UIView* view = (__bridge UIView*)wi->window_handle;
    view.contentScaleFactor = [[UIScreen mainScreen] scale];
    [view.layer addSublayer:layer];
    // PORTED: backingScaleFactor replaced with contentScaleFactor (UIKit)
    layer.contentsScale = view.contentScaleFactor;
    // Store the layer pointer
    wi->surface_handle = (__bridge_retained void*)layer;
    return true;
}

void CocoaTools::DestroyMetalLayer(WindowInfo* wi)
{
    if (![NSThread isMainThread])
    {
        dispatch_sync_f(dispatch_get_main_queue(), wi, [](void* ctx){
            DestroyMetalLayer(static_cast<WindowInfo*>(ctx));
        });
        return;
    }

    CAMetalLayer* layer = (__bridge_transfer CAMetalLayer*)wi->surface_handle;
    if (!layer)
        return;
    wi->surface_handle = nullptr;
    [layer removeFromSuperlayer];
}

std::optional<float> CocoaTools::GetViewRefreshRate(const WindowInfo& wi)
{
    if (![NSThread isMainThread])
    {
        __block std::optional<float> ret;
        dispatch_sync(dispatch_get_main_queue(), ^{ ret = GetViewRefreshRate(wi); });
        return ret;
    }

    // PORTED: NSScreen → UIScreen (Audit Section 4.3)
    // iOS devices typically have 60Hz or 120Hz ProMotion displays
    UIScreen* screen = [UIScreen mainScreen];
    if (@available(iOS 15.0, *)) {
        return static_cast<float>([screen maximumFramesPerSecond]);
    }
    return 60.0f;
}

// PORTED: MarkHelpMenu — no-op on iOS (no NSMenu equivalent)
void CocoaTools::MarkHelpMenu(void* menu)
{
    // No equivalent on iOS (Audit Section 4.3)
}

// Sound playback (iOS uses AVAudioPlayer instead of NSSound)
bool Common::PlaySoundAsync(const char* path)
{
    // PORTED: NSSound → AVAudioPlayer (Audit Section 9.2)
    NSString* nspath = [NSString stringWithUTF8String:path];
    NSData* data = [NSData dataWithContentsOfFile:nspath];
    if (!data) return false;

    AVAudioPlayer* player = [[AVAudioPlayer alloc] initWithData:data error:nil];
    [player play];
    return true;
}

// Bundle path (identical API on iOS)
std::optional<std::string> CocoaTools::GetBundlePath()
{
    std::optional<std::string> ret;
    @autoreleasepool {
        NSURL* url = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        if (url)
            ret = std::string([url fileSystemRepresentation]);
    }
    return ret;
}

// PORTED: GetNonTranslocatedBundlePath — no translocation on iOS, returns same as GetBundlePath
std::optional<std::string> CocoaTools::GetNonTranslocatedBundlePath()
{
    return GetBundlePath();
}

// PORTED: GetResourcePath — uses NSBundle (Audit Section 6.4)
std::optional<std::string> CocoaTools::GetResourcePath()
{
    @autoreleasepool {
        if (NSBundle* bundle = [NSBundle mainBundle])
        {
            NSString* rsrc = [bundle resourcePath];
            // PORTED: iOS resources are at the bundle root, append /resources
            NSString* root = [bundle bundlePath];
            if ([rsrc isEqualToString:root])
                rsrc = [rsrc stringByAppendingString:@"/resources"];
            return std::string([rsrc UTF8String]);
        }
        return std::nullopt;
    }
}

// PORTED: MoveToTrash — uses NSFileManager (identical on iOS)
std::optional<std::string> CocoaTools::MoveToTrash(std::string_view file)
{
    NSURL* url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:std::string(file).c_str()]];
    NSURL* new_url;
    if (![[NSFileManager defaultManager] trashItemAtURL:url resultingItemURL:&new_url error:nil])
        return std::nullopt;
    return std::string([new_url fileSystemRepresentation]);
}

// PORTED: ShowInFinder — no-op on iOS (no Finder)
bool CocoaTools::ShowInFinder(std::string_view file)
{
    return false;
}

// PORTED: CreateWindow — UIWindow instead of NSWindow (Audit Section 4.3)
void* CocoaTools::CreateWindow(std::string_view title, u32 width, u32 height)
{
    UIWindow* window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    window.backgroundColor = [UIColor blackColor];
    // PORTED: setTitle equivalent not available on iOS UIWindow
    // Title is set via the UIViewController's navigation item
    [window makeKeyAndVisible];
    return (__bridge_retained void*)window;
}

void CocoaTools::DestroyWindow(void* window)
{
    (void)(__bridge_transfer UIWindow*)window;
}

void CocoaTools::GetWindowInfoFromWindow(WindowInfo* wi, void* cf_window)
{
    if (cf_window)
    {
        // PORTED: NSWindow → UIWindow (Audit Section 4.3)
        UIWindow* window = (__bridge UIWindow*)cf_window;
        float scale = [window screen].scale;
        UIView* view = window.rootViewController.view;
        CGRect dims = view.frame;
        wi->type = WindowInfo::Type::MacOS;
        wi->window_handle = (__bridge void*)view;
        wi->surface_width = dims.size.width * scale;
        wi->surface_height = dims.size.height * scale;
        wi->surface_scale = scale;
    }
    else
    {
        wi->type = WindowInfo::Type::Surfaceless;
    }
}

// PORTED: RunCocoaEventLoop — replaced with CFRunLoop for iOS (Audit Section 4.3)
void CocoaTools::RunCocoaEventLoop(bool forever)
{
    if (forever) {
        // iOS apps use UIApplicationMain — this should not be called directly
        // If called, fall back to CFRunLoopRun
        CFRunLoopRun();
    } else {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.0, TRUE);
    }
}

void CocoaTools::StopMainThreadEventLoop()
{
    CFRunLoopStop(CFRunLoopGetMain());
}
