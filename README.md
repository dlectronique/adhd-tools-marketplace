# ADHD working mode — a Claude Code skill

*Created to support my ADHD, probably useful for everyone. Always-on Claude Code working-mode skill that helps you stay in-flow, action-first, one step at a time. Transparent by default.*

**Built by and for someone with ADHD — but you don't need ADHD to benefit.**

If you've ever lost the thread halfway through a wall of text, stalled out staring at a vague twelve-step task, or groaned at re-explaining context you know you already gave — this is for you. ADHD just turns the volume all the way up on friction that everyone feels, which makes it a great design target: build for the person who feels it most, and the result is calmer, faster, and clearer for everyone.

It's an always-on working *mode* for collaborating with Claude on real software work. In short, it makes Claude:

- **Lead with the action** — the next move first, one screen max, no preamble.
- **Give you the ONE next step**, not the whole 12-item tree — and start it *for* you to kill the blank-page problem.
- **Present one decision at a time**, with each option self-contained (assume low context).
- **Keep state in the tracker, not your head** — progress on the issue/PR, the plan in the work-item description — so a fresh session or a teammate can pick up cold and you never re-explain.
- **Estimate time concretely**, name where you are in a sequence, celebrate real wins, catch rabbit-holes, and know when to stop.
- **Run work in parallel** so nothing waits, while still handing you a single focus.
- **Build to a real production bar** (tests, security, a11y, conventions) — the leanness is in the *packaging*, never the rigor.

## Install

```
/plugin marketplace add dlectronique/adhd-mode-marketplace
/plugin install adhd-working-mode@adhd-mode
```

(Assumes the repo lives at `github.com/dlectronique/adhd-mode-marketplace`.)

Then start a new session — the skill applies by default. Ask Claude for depth anytime; this sets the default, not a ceiling.

## What's inside

```
.claude-plugin/marketplace.json          # marketplace manifest
plugins/adhd-working-mode/
├── .claude-plugin/plugin.json            # plugin manifest
└── skills/adhd-working-mode/SKILL.md     # the skill itself
```

## License

MIT — see [LICENSE](LICENSE). Use it, fork it, adapt it to how *your* brain works.
