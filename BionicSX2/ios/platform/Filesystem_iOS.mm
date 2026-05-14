// PORTED FROM: FileSystem.cpp, common/Darwin/DarwinMisc.cpp — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 6.4 (iOS sandbox directory conventions),
//                  Section 10.3 (iOS bundle structure requirements)
// STATUS: NEW — iOS-specific filesystem paths using NSSearchPathForDirectoriesInDomains

#import <Foundation/Foundation.h>
#include "FileSystem.h"
#include <string>

// Audit Section 6.4: Never use hardcoded absolute paths on iOS
// iOS sandbox restricts all file access to app container

static std::string GetDocumentsDir()
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if ([paths count] == 0) return "";
    return std::string([[paths objectAtIndex:0] UTF8String]);
}

static std::string GetCachesDir()
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if ([paths count] == 0) return "";
    return std::string([[paths objectAtIndex:0] UTF8String]);
}

// Audit Section 6.4: Application data directory
std::string GetAppDataPath()
{
    return GetDocumentsDir();
}

// Audit Section 6.4: BIOS directory — create if not exists
std::string GetBIOSPath()
{
    NSString* biosDir = [NSString stringWithFormat:@"%s/BIOS", GetDocumentsDir().c_str()];
    NSFileManager* fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:biosDir]) {
        [fm createDirectoryAtPath:biosDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return std::string([biosDir UTF8String]);
}

// Audit Section 2.6: ISO/CHD directory — iOS uses file-based game loading only
// Physical optical drive code (CDVD/Darwin/) is excluded entirely on iOS
std::string GetGamesPath()
{
    NSString* gamesDir = [NSString stringWithFormat:@"%s/Games", GetDocumentsDir().c_str()];
    NSFileManager* fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:gamesDir]) {
        [fm createDirectoryAtPath:gamesDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return std::string([gamesDir UTF8String]);
}

// Audit Section 10.3: Memory card directory
std::string GetMemcardPath()
{
    NSString* memcardDir = [NSString stringWithFormat:@"%s/Memcards", GetDocumentsDir().c_str()];
    NSFileManager* fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:memcardDir]) {
        [fm createDirectoryAtPath:memcardDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return std::string([memcardDir UTF8String]);
}

// Audit Section 6.4: Cache directory for shader caches and temporary data
std::string GetCachePath()
{
    return GetCachesDir();
}
