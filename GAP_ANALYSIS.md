# Gap Analysis: jido_opencode vs Production Adapters

## Summary

jido_opencode is **functional but minimal**. Compared to jido_codex, jido_claude, and jido_gemini, it's missing several modules that make the other adapters production-ready.

---

## Priority 1: CRITICAL (Must Have)

### 1. ✅ Error Module
**Status:** Using generic Jido.Harness.Error  
**What:** Custom error types for better error handling  
**Priority:** HIGH  
**Effort:** Low (1-2 hours)

```elixir
defmodule Jido.Opencode.Error do
  defmodule ValidationError do
    defexception [:message, :field]
  end
  
  defmodule ExecutionError do
    defexception [:message, :details]
  end
  
  defmodule CompatibilityError do
    defexception [:message, :reason]
  end
end
```

### 2. ✅ Compatibility Module  
**Status:** Stub only (`start_opencode_server` placeholder)  
**What:** Check if OpenCode CLI is installed and compatible  
**Priority:** HIGH  
**Effort:** Low-Medium (2-3 hours)

```elixir
defmodule Jido.Opencode.Compatibility do
  def cli_installed? do
    match?({_, 0}, System.cmd("which", ["opencode"]))
  end
  
  def compatible?(version \\ nil) do
    # Check OpenCode version meets minimum
  end
end
```

### 3. ✅ Options Module
**Status:** Not implemented  
**What:** Normalize and validate all options from RunRequest  
**Priority:** HIGH  
**Effort:** Medium (3-4 hours)

---

## Priority 2: IMPORTANT (Should Have)

### 4. ✅ Mix Tasks
**Status:** None implemented  
**What:** CLI commands for users  
**Priority:** MEDIUM  
**Effort:** Medium (3-4 hours)

Needed tasks:
- `mix opencode.install` - Check/install OpenCode CLI
- `mix opencode.compat` - Run compatibility check
- `mix opencode.smoke` - Run smoke test

### 5. ✅ Session Registry
**Status:** Not implemented  
**What:** Track active sessions for cancellation  
**Priority:** MEDIUM  
**Effort:** Medium (4-5 hours)

Current issue: `cancel/1` tries to abort but doesn't track sessions!

### 6. ✅ Version Function
**Status:** Missing  
**What:** Public API to get version  
**Priority:** LOW  
**Effort:** Trivial (5 min)

---

## Priority 3: NICE TO HAVE (Could Have)

### 7. ⭕ Separate Stream Module
**Status:** Inline in client.ex  
**What:** Extract streaming logic  
**Priority:** LOW  
**Effort:** Medium  
**Note:** Currently functional, refactoring only

### 8. ⭕ Application Environment Config
**Status:** Hardcoded references  
**What:** Allow module injection for testing  
**Priority:** LOW  
**Effort:** Low  
**Note:** Testing convenience only

### 9. ⭕ Enhanced Runtime Contract
**Status:** Basic install steps  
**What:** Richer command templates, probes  
**Priority:** LOW  
**Effort:** Low  
**Note:** Currently functional

---

## Key Differences Explained

### Why jido_codex is More Complex:

1. **Codex uses sub-process execution** - needs system_command, execution context
2. **Codex has multiple transports** - exec vs app_server modes
3. **Codex needs session management** - long-running sub-processes

### Why jido_opencode Can Be Simpler:

1. **OpenCode uses HTTP API** - cleaner than CLI parsing
2. **OpenCode server handles sessions** - less state to manage
3. **OpenCode SDK is type-safe** - easier to integrate

---

## Recommendation

### Minimum Viable for Transfer:

To be accepted into `agentjido` org, implement at least:

1. ✅ **Error Module** - Better error handling
2. ✅ **Compatibility Module** - CLI version checking  
3. ✅ **Mix Tasks** - User-friendly CLI (install, compat, smoke)
4. ✅ **Fix cancel/1** - Make it actually work with session tracking

**Time Estimate:** 8-12 hours of work

### Production-Ready:

For full parity with jido_codex:

- Add all Priority 1 & 2 items
- Add comprehensive integration tests
- Add fixtures/stubs for testing

**Time Estimate:** 20-30 hours of work

---

## Current Status vs Goal

| Feature | Current | Goal | Priority |
|---------|---------|------|----------|
| Adapter behaviour | ✅ | ✅ | - |
| HTTP Client | ✅ | ✅ | - |
| Event translation | ✅ | ✅ | - |
| run_with_schema | ✅ | ✅ | - |
| Error module | ❌ | ✅ | **P1** |
| Compatibility | ⚠️ | ✅ | **P1** |
| Mix tasks | ❌ | ✅ | **P2** |
| Session registry | ❌ | ✅ | **P2** |
| Version function | ❌ | ✅ | P3 |
| Stream module | ⚠️ | ⭕ | P3 |
| Config injection | ❌ | ⭕ | P3 |

**Legend:**
- ✅ Complete
- ⚠️ Partial/functional
- ❌ Missing
- ⭕ Nice to have

---

## Next Steps

**For immediate transfer readiness:**
1. Implement Error module (2 hours)
2. Implement Compatibility module (3 hours)  
3. Add basic Mix tasks (3 hours)
4. Show Mike for feedback

**For full production readiness:**
1. All Priority 1 & 2 items
2. Integration tests with real OpenCode
3. Documentation updates
