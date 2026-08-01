#!/usr/bin/env bash
#
# memory-inherit — make Claude Code's auto-memory inherit down a directory tree.
#
# THE PROBLEM
#   Auto-memory lives in ~/.claude/projects/<cwd-slug>/memory/, keyed to the
#   *exact* working directory. A repo checkout, and every git worktree under
#   it, each hash to a different slug — so none of them see the memory written
#   at the root of the tree. The store looks hierarchical and does not
#   actually inherit. Memory silently reads as empty exactly where most of the
#   work happens, and you never get an error saying so.
#
# WHAT THIS DOES
#   On session start, walk up from cwd. The first ancestor that owns a real
#   memory/ directory is the "memory root". Symlink this session's slug at it.
#
#   The root is chosen by where memory already exists, so a tree opts in
#   simply by having memory at its root. No config, no path list, nothing to
#   keep in sync as worktrees come and go.
#
# SAFETY
#   Never overwrites an existing memory/ entry (real directory or symlink).
#   Never walks above $HOME. Always exits 0 — a memory link is never worth
#   breaking a session over. Prints nothing on stdout: SessionStart stdout is
#   injected into the model's context, so noise here is a permanent context
#   tax on every session. Diagnostics go to the log file below.

set -uo pipefail

LOG="${HOME}/.claude/memory-inherit.log"
PROJECTS="${HOME}/.claude/projects"

log() {
    mkdir -p "$(dirname "$LOG")" 2>/dev/null
    printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$*" >>"$LOG" 2>/dev/null || true
}

# Claude Code's slug: the absolute path with / . and _ each mapped to '-'.
slug_of() { printf '%s' "$1" | tr '/._' '---'; }

payload="$(cat 2>/dev/null || true)"

# Prefer transcript_path — it *contains* the real slug, so no guessing.
# jq when available, plain sed otherwise, so this works on a bare machine.
if command -v jq >/dev/null 2>&1; then
    transcript="$(printf '%s' "$payload" | jq -r '.transcript_path // empty' 2>/dev/null)"
    cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)"
else
    transcript="$(printf '%s' "$payload" |
        sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
    cwd="$(printf '%s' "$payload" |
        sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
fi

[ -n "${cwd:-}" ] || cwd="$PWD"

if [ -n "${transcript:-}" ]; then
    slug="$(basename "$(dirname "$transcript")")"
else
    slug="$(slug_of "$cwd")"
fi

target="${PROJECTS}/${slug}/memory"

# Already has memory — a real directory, or a link from an earlier run.
if [ -e "$target" ] || [ -L "$target" ]; then
    exit 0
fi

# Walk up looking for the nearest ancestor that owns real memory.
dir="$(dirname "$cwd")"
source_dir=""
while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    case "$dir" in
        "$HOME" | "$HOME"/*) ;;
        *) break ;;                     # never climb above $HOME
    esac

    candidate="${PROJECTS}/$(slug_of "$dir")/memory"
    if [ -d "$candidate" ]; then
        # Resolve one hop so we link at the real store, not a chain of links.
        # Chains break the moment any middle link is cleaned up.
        if [ -L "$candidate" ]; then
            candidate="$(readlink "$candidate")"
        fi
        source_dir="$candidate"
        break
    fi

    [ "$dir" = "$HOME" ] && break
    dir="$(dirname "$dir")"
done

# No memory root above us. Correct outcome for an unrelated project.
[ -n "$source_dir" ] || exit 0

mkdir -p "${PROJECTS}/${slug}" 2>/dev/null
if ln -s "$source_dir" "$target" 2>/dev/null; then
    log "linked ${slug} -> ${source_dir} (cwd=${cwd})"
else
    log "FAILED to link ${slug} -> ${source_dir} (cwd=${cwd})"
fi

exit 0
