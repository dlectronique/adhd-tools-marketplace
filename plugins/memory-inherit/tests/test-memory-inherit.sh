#!/usr/bin/env bash
#
# Tests for memory-inherit.sh.
#
# Runs entirely against a throwaway $HOME, so it never reads or writes the
# real memory estate. Run it directly:  ./tests/test-memory-inherit.sh
#
# Each case builds a fake ~/.claude/projects tree, feeds the hook the same
# JSON payload Claude Code sends on SessionStart, and asserts on the result.

set -uo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/scripts/memory-inherit.sh"

pass=0
fail=0

ok()   { printf '  ok   %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf '  FAIL %s\n     expected: %s\n     actual:   %s\n' "$1" "$2" "$3"; fail=$((fail + 1)); }
check() { [ "$2" = "$3" ] && ok "$1" || bad "$1" "$2" "$3"; }

slug_of() { printf '%s' "$1" | tr '/._' '---'; }

# Fresh sandbox per case: a fake HOME with a fake projects tree.
new_sandbox() {
    SANDBOX="$(mktemp -d)"
    export HOME="$SANDBOX"
    PROJECTS="$SANDBOX/.claude/projects"
    mkdir -p "$PROJECTS"
}

# Give <dir> a real memory/ directory holding one file, making it a memory root.
seed_root() {
    local dir="$1"
    mkdir -p "$dir" "$PROJECTS/$(slug_of "$dir")/memory"
    printf 'seed\n' > "$PROJECTS/$(slug_of "$dir")/memory/MEMORY.md"
}

run_hook() {
    printf '{"cwd":"%s","hook_event_name":"SessionStart","source":"startup"}' "$1" |
        "$HOOK" 2>/dev/null
}

memory_of() { printf '%s' "$PROJECTS/$(slug_of "$1")/memory"; }

if [ ! -x "$HOOK" ]; then
    printf 'FATAL: hook not found or not executable: %s\n' "$HOOK"
    exit 1
fi

REAL_HOME="$HOME"
trap 'HOME="$REAL_HOME"' EXIT

printf '\nmemory-inherit\n'

# ── 1. The case the whole plugin exists for ──────────────────────────────────
printf '\n1. a nested dir with no memory inherits from its ancestor\n'
new_sandbox
seed_root "$SANDBOX/tree"
child="$SANDBOX/tree/repo/.claude/worktrees/wt1"
mkdir -p "$child"
run_hook "$child"
check "link created" "yes" "$([ -L "$(memory_of "$child")" ] && echo yes || echo no)"
check "content readable through it" "seed" "$(cat "$(memory_of "$child")/MEMORY.md" 2>/dev/null)"

# ── 2. Idempotency — a hook runs on every single session ─────────────────────
printf '\n2. rerunning is a no-op\n'
before="$(readlink "$(memory_of "$child")")"
run_hook "$child"; run_hook "$child"
check "target unchanged" "$before" "$(readlink "$(memory_of "$child")")"
check "still exactly one link" "1" "$(find "$(dirname "$(memory_of "$child")")" -maxdepth 1 -name memory | wc -l | tr -d ' ')"

# ── 3. Never destroy memory that already exists ──────────────────────────────
printf '\n3. an existing real memory dir is left alone\n'
new_sandbox
seed_root "$SANDBOX/tree"
own="$SANDBOX/tree/haus"
mkdir -p "$own" "$PROJECTS/$(slug_of "$own")/memory"
printf 'mine\n' > "$PROJECTS/$(slug_of "$own")/memory/MEMORY.md"
run_hook "$own"
check "not turned into a link" "no" "$([ -L "$(memory_of "$own")" ] && echo yes || echo no)"
check "own content intact" "mine" "$(cat "$(memory_of "$own")/MEMORY.md")"

# ── 4. No root above means do nothing at all ─────────────────────────────────
printf '\n4. no memory root above -> no side effects\n'
new_sandbox
orphan="$SANDBOX/nowhere/deep"
mkdir -p "$orphan"
run_hook "$orphan"
check "nothing created" "no" "$([ -e "$(memory_of "$orphan")" ] && echo yes || echo no)"

# ── 5. Nearest ancestor wins, not the highest one ────────────────────────────
printf '\n5. the nearest ancestor wins\n'
new_sandbox
seed_root "$SANDBOX/outer"
mkdir -p "$PROJECTS/$(slug_of "$SANDBOX/outer/inner")/memory"
printf 'inner\n' > "$PROJECTS/$(slug_of "$SANDBOX/outer/inner")/memory/MEMORY.md"
deep="$SANDBOX/outer/inner/a/b"
mkdir -p "$deep"
run_hook "$deep"
check "resolved to nearest" "inner" "$(cat "$(memory_of "$deep")/MEMORY.md" 2>/dev/null)"

# ── 6. Link at the real store, never build a chain ───────────────────────────
printf '\n6. links point at the real store, not at another link\n'
new_sandbox
seed_root "$SANDBOX/tree"
mid="$SANDBOX/tree/mid"; mkdir -p "$mid"
run_hook "$mid"
leaf="$SANDBOX/tree/mid/leaf"; mkdir -p "$leaf"
run_hook "$leaf"
check "leaf skips the intermediate link" "$(memory_of "$SANDBOX/tree")" "$(readlink "$(memory_of "$leaf")")"

# ── 7. Contract with the harness ─────────────────────────────────────────────
printf '\n7. harness contract\n'
new_sandbox
seed_root "$SANDBOX/tree"
q="$SANDBOX/tree/quiet"; mkdir -p "$q"
out="$(run_hook "$q")"
check "silent on stdout (it is injected into context)" "" "$out"
printf '{"cwd":"%s"}' "$q" | "$HOOK" >/dev/null 2>&1
check "exit 0 on the happy path" "0" "$?"
printf 'not json at all' | "$HOOK" >/dev/null 2>&1
check "exit 0 on a malformed payload" "0" "$?"
printf '' | "$HOOK" >/dev/null 2>&1
check "exit 0 on an empty payload" "0" "$?"

# ── 8. transcript_path is authoritative when present ─────────────────────────
printf '\n8. transcript_path decides the slug when present\n'
new_sandbox
seed_root "$SANDBOX/tree"
child2="$SANDBOX/tree/x"; mkdir -p "$child2"
printf '{"cwd":"%s","transcript_path":"%s/odd-slug-9/s.jsonl"}' "$child2" "$PROJECTS" |
    "$HOOK" 2>/dev/null
check "used the transcript slug" "yes" "$([ -L "$PROJECTS/odd-slug-9/memory" ] && echo yes || echo no)"
check "did not use the derived slug" "no" "$([ -e "$(memory_of "$child2")" ] && echo yes || echo no)"

# ── 9. Never climb above $HOME ───────────────────────────────────────────────
printf '\n9. the walk stops at $HOME\n'
new_sandbox
outside="$(mktemp -d)"
mkdir -p "$PROJECTS/$(slug_of "$outside")/memory"
run_hook "$outside/sub"
check "no link for a path outside HOME" "no" "$([ -e "$PROJECTS/$(slug_of "$outside/sub")/memory" ] && echo yes || echo no)"
rm -rf "$outside"

printf '\n%s passed, %s failed\n\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
