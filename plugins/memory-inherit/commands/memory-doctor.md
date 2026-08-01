---
description: Check whether Claude Code's memory actually resolves in this directory
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/memory-doctor.sh":*)
---

Run the memory doctor and report what it found:

!`bash "${CLAUDE_PLUGIN_ROOT}/scripts/memory-doctor.sh"`

Read the output above and tell the user, in two or three lines:

- whether memory resolves in this directory, and if it is inherited, from where
- the single most useful thing to do next, if anything is wrong

Do not repeat the raw output back to them — they can already see it. If
everything is OK, say so plainly and stop; no suggestions needed.
