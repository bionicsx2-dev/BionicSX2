#include "common/Assertions.h"
#include "common/BitUtils.h"
#include "common/Console.h"
#include "common/Error.h"
#include "common/HostSys.h"

#import <Foundation/Foundation.h>

#include <cstdio>
#include <csignal>
#include <mutex>
#include <unistd.h>
#include <mach/mach.h>
#include <sys/sysctl.h>

static size_t GetPageSize()
{
    static size_t s_pagesize = 0;
    if (s_pagesize == 0) {
        vm_size_t psize;
        host_page_size(mach_host_self(), &psize);
        s_pagesize = psize;
    }
    return s_pagesize;
}

size_t HostSys::GetRuntimePageSize()
{
    return GetPageSize();
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
    return fmt::format("{}_{}", prefix, static_cast<unsigned>(getpid()));
}

void* HostSys::CreateSharedMemory(const char* name, size_t size)
{
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
    pxAssertRel(Common::IsAlignedPow2(size, GetPageSize()), "Size is page aligned");

    if (jit) {
        NSLog(@"[BionicSX2] MAP_JIT not available — JIT disabled, interpreter path active");
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
    __builtin___clear_cache(reinterpret_cast<char*>(address),
                            reinterpret_cast<char*>(address) + size);
}
