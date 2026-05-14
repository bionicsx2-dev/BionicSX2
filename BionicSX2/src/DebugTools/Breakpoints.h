// SPDX-FileCopyrightText: 2002-2026 PCSX2 Dev Team
// SPDX-License-Identifier: GPL-2.0+

#pragma once

#include <algorithm>
#include <iterator>
#include <vector>

#include "ExpressionParser.h"
#include "common/Pcsx2Types.h"

enum BreakPointCpu
{
	BREAKPOINT_EE = 0x01,
	BREAKPOINT_IOP = 0x02,
	BREAKPOINT_IOP_AND_EE = 0x03
};

inline const std::array<BreakPointCpu, 2> DEBUG_CPUS = {
	BREAKPOINT_EE,
	BREAKPOINT_IOP,
};

enum MemCheckCondition
{
	MEMCHECK_READ = 0x01,
	MEMCHECK_WRITE = 0x02,
	MEMCHECK_WRITE_ONCHANGE = 0x04,

	MEMCHECK_READWRITE = 0x03,
	MEMCHECK_INVALID = 0x08,
};

enum MemCheckResult
{
	MEMCHECK_IGNORE = 0x00,
	MEMCHECK_LOG = 0x01,
	MEMCHECK_BREAK = 0x02,

	MEMCHECK_BOTH = 0x03,
};

#ifdef PCSX2_TARGET_IOS

class DebugInterface;

struct BreakPointCond
{
	u32 Evaluate() { return 1; }
};

struct BreakPoint
{
	u32 addr = 0;
	bool enabled = false;
	bool temporary = false;
	bool stepping = false;
	bool hasCond = false;
	BreakPointCond cond;
	BreakPointCpu cpu;
	std::string description;
};

struct MemCheck
{
	MemCheck() : start(0), end(0), memCond(MEMCHECK_READ), result(MEMCHECK_IGNORE), cpu(BREAKPOINT_EE), numHits(0), lastPC(0), lastAddr(0), lastSize(0) {}
	u32 start;
	u32 end;
	bool hasCond = false;
	BreakPointCond cond;
	MemCheckCondition memCond;
	MemCheckResult result;
	BreakPointCpu cpu;
	std::string description;
	u32 numHits;
	u32 lastPC;
	u32 lastAddr;
	int lastSize;
	void Action(u32 addr, bool write, int size, u32 pc) {}
	void JitBefore(u32 addr, bool write, int size, u32 pc) {}
	void JitCleanup() {}
	void Log(u32 addr, bool write, int size, u32 pc) {}
};

class CBreakPoints
{
public:
	static const size_t INVALID_BREAKPOINT = -1;
	static const size_t INVALID_MEMCHECK = -1;

	static bool IsAddressBreakPoint(BreakPointCpu, u32) { return false; }
	static bool IsAddressBreakPoint(BreakPointCpu, u32, bool*) { return false; }
	static bool IsTempBreakPoint(BreakPointCpu, u32) { return false; }
	static void AddBreakPoint(BreakPointCpu, u32, bool = false, bool = true, bool = false) {}
	static void RemoveBreakPoint(BreakPointCpu, u32) {}
	static void ClearAllBreakPoints() {}
	static void ClearTemporaryBreakPoints() {}
	static void AddMemCheck(BreakPointCpu, u32, u32, MemCheckCondition, MemCheckResult) {}
	static void RemoveMemCheck(BreakPointCpu, u32, u32) {}
	static void ClearAllMemChecks() {}
	static void SetSkipFirst(BreakPointCpu, u32) {}
	static u32 CheckSkipFirst(BreakPointCpu, u32) { return 0; }
	static void ClearSkipFirst(BreakPointCpu = BREAKPOINT_IOP_AND_EE) {}
	static void CommitClearSkipFirst(BreakPointCpu) {}
	static size_t GetNumBreakpoints() { return 0; }
	static size_t GetNumMemchecks() { return 0; }
	static const std::vector<MemCheck> GetMemChecks(BreakPointCpu) { return {}; }
	static BreakPointCond* GetBreakPointCondition(BreakPointCpu, u32) { return nullptr; }
	static void SetBreakpointTriggered(bool, BreakPointCpu = BREAKPOINT_IOP_AND_EE) {}
	static bool GetBreakpointTriggered() { return false; }
	static bool GetCorePaused() { return false; }
	static void SetCorePaused(bool) {}
};

#else

#include "DebugInterface.h"

struct BreakPointCond
{
	DebugInterface* debug = nullptr;
	PostfixExpression expression;
	std::string expressionString;

	u32 Evaluate()
	{
		u64 result;
		std::string error;
		if (!debug->parseExpression(expression, result, error) || result == 0)
			return 0;
		return 1;
	}
};

struct BreakPoint
{
	u32 addr = 0;
	bool enabled = false;
	bool temporary = false;
	bool stepping = false;

	bool hasCond = false;
	BreakPointCond cond;
	BreakPointCpu cpu;

	std::string description;

	bool operator==(const BreakPoint& other) const
	{
		return addr == other.addr;
	}
	bool operator<(const BreakPoint& other) const
	{
		return addr < other.addr;
	}
};

struct MemCheck
{
	MemCheck();
	u32 start;
	u32 end;

	bool hasCond;
	BreakPointCond cond;
	MemCheckCondition memCond;
	MemCheckResult result;
	BreakPointCpu cpu;

	std::string description;

	u32 numHits;

	u32 lastPC;
	u32 lastAddr;
	int lastSize;

	void Action(u32 addr, bool write, int size, u32 pc);
	void JitBefore(u32 addr, bool write, int size, u32 pc);
	void JitCleanup();

	void Log(u32 addr, bool write, int size, u32 pc);

	bool operator==(const MemCheck& other) const
	{
		return start == other.start && end == other.end;
	}
};

class CBreakPoints
{
public:
	static const size_t INVALID_BREAKPOINT = -1;
	static const size_t INVALID_MEMCHECK = -1;

	static bool IsAddressBreakPoint(BreakPointCpu cpu, u32 addr);
	static bool IsAddressBreakPoint(BreakPointCpu cpu, u32 addr, bool* enabled);
	static bool IsTempBreakPoint(BreakPointCpu cpu, u32 addr);
	static bool IsSteppingBreakPoint(BreakPointCpu cpu, u32 addr);
	static void AddBreakPoint(BreakPointCpu cpu, u32 addr, bool temp = false, bool enabled = true, bool stepping = false);
	static void RemoveBreakPoint(BreakPointCpu cpu, u32 addr);
	static void ChangeBreakPoint(BreakPointCpu cpu, u32 addr, bool enable);
	static void ClearAllBreakPoints();
	static void ClearTemporaryBreakPoints();

	static void ChangeBreakPointAddCond(BreakPointCpu cpu, u32 addr, const BreakPointCond& cond);
	static void ChangeBreakPointRemoveCond(BreakPointCpu cpu, u32 addr);
	static BreakPointCond* GetBreakPointCondition(BreakPointCpu cpu, u32 addr);
	static void ChangeBreakPointDescription(BreakPointCpu cpu, u32 addr, const std::string& description);

	static void AddMemCheck(BreakPointCpu cpu, u32 start, u32 end, MemCheckCondition cond, MemCheckResult result);
	static void RemoveMemCheck(BreakPointCpu cpu, u32 start, u32 end);
	static void ChangeMemCheck(BreakPointCpu cpu, u32 start, u32 end, MemCheckCondition cond, MemCheckResult result);
	static void ChangeMemCheckRemoveCond(BreakPointCpu cpu, u32 start, u32 end);
	static void ChangeMemCheckAddCond(BreakPointCpu cpu, u32 start, u32 end, const BreakPointCond& cond);
	static void ChangeMemCheckDescription(BreakPointCpu cpu, u32 start, u32 end, const std::string& description);
	static void ClearAllMemChecks();

	static void SetSkipFirst(BreakPointCpu cpu, u32 pc);
	static u32 CheckSkipFirst(BreakPointCpu cpu, u32 pc);
	static void ClearSkipFirst(BreakPointCpu cpu = BREAKPOINT_IOP_AND_EE);
	static void CommitClearSkipFirst(BreakPointCpu cpu);

	static const std::vector<MemCheck> GetMemCheckRanges();

	static const std::vector<MemCheck> GetMemChecks(BreakPointCpu cpu);
	static const std::vector<BreakPoint> GetBreakpoints(BreakPointCpu cpu, bool includeTemp);

	static size_t GetNumBreakpoints()
	{
		return std::count_if(breakPoints_.begin(), breakPoints_.end(), [](BreakPoint& bp) { return !bp.temporary; });
	}
	static size_t GetNumMemchecks() { return memChecks_.size(); }

	static void Update(BreakPointCpu cpu = BREAKPOINT_IOP_AND_EE, u32 addr = 0);

	static void SetBreakpointTriggered(bool triggered, BreakPointCpu cpu = BreakPointCpu::BREAKPOINT_IOP_AND_EE)
	{
		breakpointTriggered_ = triggered;
		breakpointTriggeredCpu_ = cpu;
	};
	static bool GetBreakpointTriggered() { return breakpointTriggered_; };
	static BreakPointCpu GetBreakpointTriggeredCpu() { return breakpointTriggeredCpu_; };

	static bool GetCorePaused() { return corePaused; };
	static void SetCorePaused(bool b) { corePaused = b; };

private:
	static size_t FindBreakpoint(BreakPointCpu cpu, u32 addr, bool matchTemp = false, bool temp = false);
	static size_t FindMemCheck(BreakPointCpu cpu, u32 start, u32 end);

	static std::vector<BreakPoint> breakPoints_;
	static u32 breakSkipFirstAtEE_;
	static bool pendingClearSkipFirstAtEE_;
	static u32 breakSkipFirstAtIop_;
	static bool pendingClearSkipFirstAtIop_;

	static bool breakpointTriggered_;
	static BreakPointCpu breakpointTriggeredCpu_;
	static bool corePaused;

	static std::vector<MemCheck> memChecks_;
	static std::vector<MemCheck*> cleanupMemChecks_;
};

#endif // PCSX2_TARGET_IOS

u32 standardizeBreakpointAddress(u32 addr);
