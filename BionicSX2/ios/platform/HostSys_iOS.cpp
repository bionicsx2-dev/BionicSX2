// PORTED FROM: common/Linux/LnxHostSys.cpp — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 6.2 (mmap/mprotect → vm_allocate/vm_protect),
//                  Section 6.3 (iOS memory constraints, MAP_JIT handling)
// STATUS: YELLOW — replaces mmap with Darwin VM API for iOS compatibility

#include "common/Assertions.h"
#include "common/Console.h"
#include "common/Error.h"
#include "common/HostSys.h"

#include <cstdio>
#include <csignal>
#include <mutex>
#include <mach/mach.h>
#include <mach/mach_vm.h>
#include <sys/sysctl.h>

static mach_vm_size_t GetPageSize()
{
    static mach_vm_size_t s_pagesize = 0;
    if (s_pagesize == 0) {
        vm_size_t psize;
        host_page_size(mach_host_self(), &psize);
        s_pagesize = psize;
    }
    return s_pagesize;
}

size_t HostSys::GetRuntimePageSize()
{
    return static_cast<size_t>(GetPageSize());
}

size_t HostSys::GetRuntimeCacheLineSize()
{
    size_t line_size = 0;
    size_t sizeof_line_size = sizeof(line_size);
    sysctlbyname("hw.cachelinesize", &line_size, &sizeof_line_size, NULL, 0);
    return line_size;
}

void HostSys::MemProtect(void* baseaddr, size_t size, const PageProtectionMode& mode)
{
    // Audit Section 6.2: Replace mprotect with vm_protect on iOS
    vm_prot_t prot = VM_PROT_NONE;
    if (mode.CanRead())    prot |= VM_PROT_READ;
    if (mode.CanWrite())   prot |= VM_PROT_WRITE;
    if (mode.CanExecute()) prot |= VM_PROT_EXECUTE;

    kern_return_t kr = vm_protect(mach_task_self(),
                                   reinterpret_cast<vm_address_t>(baseaddr),
                                   size, FALSE, prot);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[BionicSX2] vm_protect failed: 0x%x", kr);
    }
}

std::string HostSys::GetFileMappingName(const char* prefix)
{
    // Audit Section 6.2: Shared memory naming — no shm_open on iOS
    return fmt::format("{}_{}", prefix, static_cast<unsigned>(getpid()));
}

void* HostSys::CreateSharedMemory(const char* name, size_t size)
{
    // Audit Section 6.2: Use vm_allocate instead of shm_open on iOS
    vm_address_t addr = 0;
    kern_return_t kr = vm_allocate(mach_task_self(), &addr, size, VM_FLAGS_ANYWHERE);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[BionicSX2] vm_allocate (shared) failed: 0x%x size=%zu", kr, size);
        return nullptr;
    }
    return reinterpret_cast<void*>(addr);
}

void HostSys::DestroySharedMemory(void* ptr)
{
    // Audit Section 6.2: vm_deallocate instead of close+shm_unlink
    vm_deallocate(mach_task_self(), reinterpret_cast<vm_address_t>(ptr), 0);
}

SharedMemoryMappingArea::SharedMemoryMappingArea(u8* base_ptr, size_t size, size_t num_pages)
    : m_base_ptr(base_ptr)
    , m_size(size)
    , m_num_pages(num_pages)
{
}

SharedMemoryMappingArea::~SharedMemoryMappingArea()
{
    pxAssertRel(m_num_mappings == 0, "No mappings left");
    vm_deallocate(mach_task_self(), reinterpret_cast<vm_address_t>(m_base_ptr), m_size);
}

std::unique_ptr<SharedMemoryMappingArea> SharedMemoryMappingArea::Create(size_t size, bool jit)
{
    // Audit Section 6.2: Replace mmap(MAP_ANONYMOUS|MAP_PRIVATE) with vm_allocate
    // Audit Section 6.3: MAP_JIT requires entitlement — gracefully skip on iOS
    pxAssertRel(Common::IsAlignedPow2(size, GetPageSize()), "Size is page aligned");

    if (jit) {
        // Audit Section 2.3-E, 6.3: No JIT entitlements in Phase 1
        // MAP_JIT not available — log and continue without executable memory
        // JIT will be enabled in a separate workstream
        NSLog(@"[BionicSX2] MAP_JIT not available — JIT disabled, interpreter path active");
        // Allocate without executable permission — interpreter doesn't need it
    }

    vm_address_t addr = 0;
    kern_return_t kr = vm_allocate(mach_task_self(), &addr, size, VM_FLAGS_ANYWHERE);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[BionicSX2] vm_allocate failed: 0x%x size=%zu", kr, size);
        return nullptr;
    }

    NSLog(@"[BionicSX2] SharedMemoryMappingArea created at 0x%llx size=%zu", (unsigned long long)addr, size);
    return std::unique_ptr<SharedMemoryMappingArea>(
        new SharedMemoryMappingArea(reinterpret_cast<u8*>(addr), size, size / GetPageSize()));
}

u8* SharedMemoryMappingArea::Map(void* file_handle, size_t file_offset,
                                  void* map_base, size_t map_size,
                                  const PageProtectionMode& mode)
{
    pxAssert(static_cast<u8*>(map_base) >= m_base_ptr &&
             static_cast<u8*>(map_base) < (m_base_ptr + m_size));

    vm_prot_t prot = VM_PROT_NONE;
    if (mode.CanRead())    prot |= VM_PROT_READ;
    if (mode.CanWrite())   prot |= VM_PROT_WRITE;
    if (mode.CanExecute()) prot |= VM_PROT_EXECUTE;

    kern_return_t kr = vm_protect(mach_task_self(),
                                   reinterpret_cast<vm_address_t>(map_base),
                                   map_size, FALSE, prot);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[BionicSX2] vm_protect (Map) failed: 0x%x", kr);
        return nullptr;
    }

    m_num_mappings++;
    return static_cast<u8*>(map_base);
}

bool SharedMemoryMappingArea::Unmap(void* map_base, size_t map_size, bool is_file)
{
    pxAssert(static_cast<u8*>(map_base) >= m_base_ptr &&
             static_cast<u8*>(map_base) < (m_base_ptr + m_size));

    // Audit Section 6.2: Replace mmap(PROT_NONE, MAP_FIXED) with vm_protect(PROT_NONE)
    kern_return_t kr = vm_protect(mach_task_self(),
                                   reinterpret_cast<vm_address_t>(map_base),
                                   map_size, FALSE, VM_PROT_NONE);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[BionicSX2] vm_protect (Unmap) failed: 0x%x", kr);
        return false;
    }

    m_num_mappings--;
    return true;
}

void HostSys::FlushInstructionCache(void* address, u32 size)
{
    // ARM64: Use __builtin___clear_cache (available on iOS)
    __builtin___clear_cache(reinterpret_cast<char*>(address),
                            reinterpret_cast<char*>(address) + size);
}
