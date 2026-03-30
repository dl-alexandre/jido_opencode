# Quick Reference Card

## 🚀 Jido Opencode Adapter - READY TO USE

**Repository:** https://github.com/dl-alexandre/jido_opencode

---

## Installation

```bash
# 1. Install OpenCode CLI
npm install -g opencode-ai

# 2. Configure OpenCode
opencode
# Run /connect and set up API key at opencode.ai/auth

# 3. Add to your Elixir project
# In mix.exs:
{:jido_opencode, "~> 0.1.0", github: "dl-alexandre/jido_opencode"}
```

---

## Basic Usage

```elixir
# Configure
config :jido_harness, :providers, %{opencode: Jido.Opencode.Adapter}

# Run
{:ok, events} = Jido.Harness.run(:opencode, "fix the bug", cwd: "/project")
```

---

## Key Functions

### Adapter
- `Jido.Harness.run(:opencode, prompt, opts)` - Run a prompt
- `Jido.Opencode.Adapter.run_with_schema(prompt, schema, opts)` - Structured output
- `Jido.Harness.cancel(:opencode, session_id)` - Cancel session

### Client (Direct API)
- `Jido.Opencode.Client.new()` - Create client
- `Jido.Opencode.Client.create_session(client, params)` - Create session
- `Jido.Opencode.Client.session_prompt(client, id, body)` - Send prompt
- `Jido.Opencode.Client.abort_session(client, id)` - Cancel

---

## Project Structure

```
jido_opencode/
├── lib/
│   ├── jido/opencode.ex              # Public API
│   └── jido/opencode/
│       ├── adapter.ex                # Main adapter
│       ├── client.ex                 # HTTP client
│       ├── event_translator.ex       # Event conversion
│       └── application.ex            # OTP app
├── test/                             # Tests
├── README.md                         # Full docs
├── EXAMPLES.md                       # Code samples
└── CHANGELOG.md                      # Versions
```

---

## Next Steps

1. ✅ **Code Complete** - All features implemented
2. 🧪 **Test with Real OpenCode** - Verify HTTP endpoints work
3. 📣 **Show Mike Hostetler** - Ask to transfer to agentjido org
4. 🔧 **Refine** - Based on testing feedback

---

## Links

- **GitHub:** https://github.com/dl-alexandre/jido_opencode
- **OpenCode:** https://opencode.ai
- **OpenCode SDK Docs:** https://opencode.ai/docs/sdk
- **Jido.Harness:** https://hexdocs.pm/jido_harness

---

**Status:** ✅ Ready for review and transfer to agentjido organization
