// PORTED FROM: common/Darwin/DarwinMisc.cpp — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 6.2 (Mach exception ports for page fault handling),
//                  Section 5.3 (sysctl CPU class detection)
// STATUS: YELLOW — removed CoreGraphics and IOKit dependencies

#include "common/Assertions.h"
#include "common/Console.h"
#include "common/CrashHandler.h"
#include "common/Darwin/DarwinMisc.h"
#include "common/Error.h"
#include "common/HostSys.h"
#include "common/Threading.h"

#include <csignal>
#include <cstring>
#include <cstdlib>
#include <optional>
#include <sys/sysctl.h>
#include <thread>
#include <mach/mach_time.h>
#include <mach/message.h>
#include <mach/task.h>
#include <mach/thread_state.h>
#include <mutex>

// Audit Section 5.3: Mach primitives for page fault handling are available on iOS
// IOKit/CoreGraphics dependencies removed per Section 4.3/8.4
// Note: HostSys::GetRuntimePageSize/GetRuntimeCacheLineSize defined in HostSys_iOS.mm

// Mach exception handler for page faults (vtlb fastmem)
// Audit Section 6.2: Mach exception ports are available on iOS

#define USE_MACH_EXCEPTION_PORTS

namespace PageFaultHandler
{
#ifdef USE_MACH_EXCEPTION_PORTS
    static void SignalHandler(mach_port_t port);
    static mach_port_t s_port = 0;
#else
    static void SignalHandler(int sig, siginfo_t* info, void* ctx);
#endif

    static std::recursive_mutex s_exception_handler_mutex;
    static bool s_in_exception_handler = false;
    static bool s_installed = false;
}

#ifdef USE_MACH_EXCEPTION_PORTS

#if defined(ARCH_X86)
#define THREAD_STATE64_COUNT x86_THREAD_STATE64_COUNT
#define THREAD_STATE64 x86_THREAD_STATE64
#define thread_state64_t x86_thread_state64_t
#elif defined(ARCH_ARM64)
#define THREAD_STATE64_COUNT ARM_THREAD_STATE64_COUNT
#define THREAD_STATE64 ARM_THREAD_STATE64
#define thread_state64_t arm_thread_state64_t
#else
#error Unknown Darwin Platform
#endif

void PageFaultHandler::SignalHandler(mach_port_t port)
{
    Threading::SetNameOfCurrentThread("Mach Exception Thread");

#pragma pack(4)
    struct
    {
        mach_msg_header_t Head;
        NDR_record_t NDR;
        exception_type_t exception;
        mach_msg_type_number_t codeCnt;
        int64_t code[2];
        int flavor;
        mach_msg_type_number_t old_stateCnt;
        natural_t old_state[THREAD_STATE64_COUNT];
        mach_msg_trailer_t trailer;
    } msg_in;

    struct
    {
        mach_msg_header_t Head;
        NDR_record_t NDR;
        kern_return_t RetCode;
        int flavor;
        mach_msg_type_number_t new_stateCnt;
        natural_t new_state[THREAD_STATE64_COUNT];
    } msg_out;
#pragma pack()
    memset(&msg_in, 0xee, sizeof(msg_in));
    memset(&msg_out, 0xee, sizeof(msg_out));
    mach_msg_size_t send_size = 0;
    mach_msg_option_t option = MACH_RCV_MSG;

    while (true)
    {
        kern_return_t r;
        if ((r = mach_msg_overwrite(&msg_out.Head, option, send_size, sizeof(msg_in), port,
                 MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL, &msg_in.Head, 0)))
        {
            pxFail(fmt::format("CRITICAL: mach_msg_overwrite: {:x}", r).c_str());
        }

        if (msg_in.Head.msgh_id == MACH_NOTIFY_NO_SENDERS)
        {
            mach_port_deallocate(mach_task_self(), port);
            return;
        }

        if (msg_in.Head.msgh_id != 2406)
        {
            pxFailRel("unknown message received");
            return;
        }

        if (msg_in.flavor != THREAD_STATE64)
        {
            pxFailRel(fmt::format("unknown flavour {}, expected {}", msg_in.flavor, THREAD_STATE64).c_str());
            return;
        }

        thread_state64_t* state = (thread_state64_t*)msg_in.old_state;

        HandlerResult result = HandlerResult::ExecuteNextHandler;
        if (!s_in_exception_handler)
        {
            s_in_exception_handler = true;

#ifdef ARCH_ARM64
            // Audit Section 6.2: ARM64 thread state for M1/M-series iOS devices
            result = HandlePageFault(reinterpret_cast<void*>(state->__pc),
                                      reinterpret_cast<void*>(msg_in.code[1]),
                                      (msg_in.code[0] & 2) != 0);
#else
            result = HandlePageFault(reinterpret_cast<void*>(state->__rip),
                                      reinterpret_cast<void*>(msg_in.code[1]),
                                      (msg_in.code[0] & 2) != 0);
#endif
            s_in_exception_handler = false;
        }

        msg_out.Head.msgh_bits = MACH_MSGH_BITS(MACH_MSGH_BITS_REMOTE(msg_in.Head.msgh_bits), 0);
        msg_out.Head.msgh_remote_port = msg_in.Head.msgh_remote_port;
        msg_out.Head.msgh_local_port = MACH_PORT_NULL;
        msg_out.Head.msgh_id = msg_in.Head.msgh_id + 100;
        msg_out.NDR = msg_in.NDR;

        if (result != HandlerResult::ContinueExecution)
        {
            msg_out.RetCode = KERN_FAILURE;
            msg_out.flavor = 0;
            msg_out.new_stateCnt = 0;
        }
        else
        {
            msg_out.RetCode = KERN_SUCCESS;
            msg_out.flavor = THREAD_STATE64;
            msg_out.new_stateCnt = THREAD_STATE64_COUNT;
            memcpy(msg_out.new_state, msg_in.old_state, THREAD_STATE64_COUNT * sizeof(natural_t));
        }

        msg_out.Head.msgh_size =
            offsetof(__typeof__(msg_out), new_state) + msg_out.new_stateCnt * sizeof(natural_t);
        send_size = msg_out.Head.msgh_size;
        option |= MACH_SEND_MSG;
    }
}

bool PageFaultHandler::Install(Error* error)
{
    exception_mask_t masks[EXC_TYPES_COUNT];
    mach_port_t ports[EXC_TYPES_COUNT];
    exception_behavior_t behaviors[EXC_TYPES_COUNT];
    thread_state_flavor_t flavors[EXC_TYPES_COUNT];
    mach_msg_type_number_t count = EXC_TYPES_COUNT;

    kern_return_t r = task_get_exception_ports(mach_task_self(), EXC_MASK_ALL,
        masks, &count, ports, behaviors, flavors);

    mach_port_t port;
    if ((r = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &port)))
    {
        pxFailRel(fmt::format("mach_port_allocate: {:x}", r).c_str());
        return false;
    }

    std::thread sig_thread(PageFaultHandler::SignalHandler, port);
    sig_thread.detach();

    if ((r = mach_port_insert_right(mach_task_self(), port, port, MACH_MSG_TYPE_MAKE_SEND)))
    {
        mach_port_deallocate(mach_task_self(), port);
        pxFailRel(fmt::format("mach_port_insert_right: {:x}", r).c_str());
        return false;
    }

    task_set_exception_ports(mach_task_self(), EXC_MASK_BAD_ACCESS, MACH_PORT_NULL, EXCEPTION_DEFAULT, THREAD_STATE_NONE);

    if ((r = thread_set_exception_ports(mach_thread_self(), EXC_MASK_BAD_ACCESS, port, EXCEPTION_STATE | MACH_EXCEPTION_CODES, THREAD_STATE64)))
    {
        mach_port_deallocate(mach_task_self(), port);
        pxFailRel(fmt::format("thread_set_exception_ports: {:x}", r).c_str());
        return false;
    }

    mach_port_t previous;
    if ((r = mach_port_request_notification(mach_task_self(), port, MACH_NOTIFY_NO_SENDERS, 0, port, MACH_MSG_TYPE_MAKE_SEND_ONCE, &previous)))
    {
        mach_port_deallocate(mach_task_self(), port);
        pxFailRel(fmt::format("mach_port_request_notification: {:x}", r).c_str());
        return false;
    }

    s_installed = true;
    s_port = port;
    return true;
}

bool PageFaultHandler::InstallSecondaryThread()
{
    kern_return_t r = thread_set_exception_ports(mach_thread_self(), EXC_MASK_BAD_ACCESS, s_port, EXCEPTION_STATE | MACH_EXCEPTION_CODES, THREAD_STATE64);
    if (r)
    {
        pxFailRel(fmt::format("thread_set_exception_ports(secondary): {:x}", r).c_str());
        return false;
    }
    return true;
}

#endif // USE_MACH_EXCEPTION_PORTS

// Audit Section 5.3: sysctl CPU class detection — available on iOS ARM64
std::vector<DarwinMisc::CPUClass> DarwinMisc::GetCPUClasses()
{
    std::vector<CPUClass> out;

    if (std::optional<u32> nperflevels = sysctlbyname_T<u32>("hw.nperflevels"))
    {
        char name[64];
        for (u32 i = 0; i < *nperflevels; i++)
        {
            snprintf(name, sizeof(name), "hw.perflevel%u.physicalcpu", i);
            std::optional<u32> physicalcpu = sysctlbyname_T<u32>(name);
            snprintf(name, sizeof(name), "hw.perflevel%u.logicalcpu", i);
            std::optional<u32> logicalcpu = sysctlbyname_T<u32>(name);

            char levelname[64];
            size_t levelname_size = sizeof(levelname);
            snprintf(name, sizeof(name), "hw.perflevel%u.name", i);
            if (0 != sysctlbyname(name, levelname, &levelname_size, nullptr, 0))
                strcpy(levelname, "???");

            if (!physicalcpu.has_value() || !logicalcpu.has_value())
            {
                Console.Warning("(PageFaultHandler) Perf level %u is missing data on %s cpus!",
                    i, !physicalcpu.has_value() ? "physical" : "logical");
                continue;
            }

            out.push_back({levelname, *physicalcpu, *logicalcpu});
        }
    }
    else if (std::optional<u32> physcpu = sysctlbyname_T<u32>("hw.physicalcpu"))
    {
        out.push_back({"Default", *physcpu, sysctlbyname_T<u32>("hw.logicalcpu").value_or(*physcpu)});
    }
    else
    {
        Console.Warning("(PageFaultHandler) Couldn't get cpu core count!");
    }

    return out;
}
