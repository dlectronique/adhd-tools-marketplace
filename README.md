# adhd-tools — a Claude Code marketplace

Two plugins, both built for the same reason: **reduce the friction between having a thought and shipping the thing.** Built by and for someone with ADHD — you don't need ADHD to benefit.

| Plugin | What it fixes |
|---|---|
| [**adhd-working-mode**](plugins/adhd-working-mode) | Claude talks in walls of text, hands you twelve options, and makes you re-explain context |
| [**memory-inherit**](plugins/memory-inherit) | Claude's memory silently reads as empty in repos and git worktrees |

```
/plugin marketplace add dlectronique/adhd-tools-marketplace
/plugin install adhd-working-mode@adhd-tools
/plugin install memory-inherit@adhd-tools
```

> `/plugin` exists in the terminal `claude` CLI, not the editor extension.

---

## adhd-working-mode

*Always-on working mode that keeps you in flow, action-first, one step at a time. Transparent by default.*

If you've ever lost the thread halfway through a wall of text, stalled out staring at a vague twelve-step task, or groaned at re-explaining context you know you already gave — this is for you. ADHD just turns the volume all the way up on friction that everyone feels, which makes it a great design target: build for the person who feels it most, and the result is calmer, faster, and clearer for everyone.

It's an always-on working *mode* for collaborating with Claude on real software work. In short, it makes Claude:

- **Lead with the action** — the next move first, one screen max, no preamble.
- **Give you the ONE next step**, not the whole 12-item tree — and start it *for* you to kill the blank-page problem.
- **Present one decision at a time**, with each option self-contained (assume low context).
- **Keep state in the tracker, not your head** — progress on the issue/PR, the plan in the work-item description — so a fresh session or a teammate can pick up cold and you never re-explain.
- **Estimate time concretely**, name where you are in a sequence, celebrate real wins, catch rabbit-holes, and know when to stop.
- **Run work in parallel** so nothing waits, while still handing you a single focus.
- **Build to a real production bar** (tests, security, a11y, conventions) — the leanness is in the *packaging*, never the rigor.
- **Prove a negative before reporting one** — "no findings" and "looked in the wrong place" produce identical output, and only one of them is good news.

Start a new session after installing — the skill applies by default. Ask Claude for depth anytime; this sets the default, not a ceiling.

---

## memory-inherit

*Your memory isn't missing. It's in a directory Claude isn't looking at.*

Claude Code keys auto-memory to your **exact** working directory. A repo checkout and every git worktree under it are different directories, so they get different stores — open a session one level down from where your memory was written and Claude sees nothing. No warning, no error, just a model that has apparently forgotten everything.

It's the same failure the working-mode skill exists to prevent, one layer down: you end up re-explaining context you already gave, except this time it isn't Claude's manners, it's the filesystem.

This plugin makes memory inherit. On session start it links the current directory at the nearest ancestor that already has memory — so a tree opts in just by having memory at its root, with no config to maintain as worktrees come and go.

Ships with `/memory-doctor` to check whether memory actually resolves where you are. Full detail in the [plugin README](plugins/memory-inherit).

---

## What's inside

```
.claude-plugin/marketplace.json              marketplace manifest
plugins/
├── adhd-working-mode/
│   ├── .claude-plugin/plugin.json
│   └── skills/adhd-working-mode/SKILL.md    the skill itself
└── memory-inherit/
    ├── .claude-plugin/plugin.json
    ├── hooks/hooks.json                     SessionStart registration
    ├── commands/memory-doctor.md            /memory-doctor
    ├── scripts/                             the hook and the doctor
    └── tests/test-memory-inherit.sh         16 cases, throwaway $HOME
```

## License

MIT — see [LICENSE](LICENSE). Use it, fork it, adapt it to how *your* brain works.
