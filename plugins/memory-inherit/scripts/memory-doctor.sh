#!/usr/bin/env bash
#
# memory-doctor — read-only report on whether memory actually resolves here.
#
# Writes nothing and changes nothing. Answers the one question that matters:
# is this directory reading the memory you think it is?

set -uo pipefail

PROJECTS="${HOME}/.claude/projects"
CWD="${1:-$PWD}"

slug_of() { printf '%s' "$1" | tr '/._' '---'; }

slug="$(slug_of "$CWD")"
mem="${PROJECTS}/${slug}/memory"

printf 'memory-doctor\n\n'
printf '  cwd   %s\n' "$CWD"
printf '  slug  %s\n\n' "$slug"

# ── Does memory resolve here at all? ─────────────────────────────────────────
if [ -L "$mem" ]; then
    tgt="$(readlink "$mem")"
    if [ -d "$mem" ]; then
        printf '  OK    memory: inherited -> %s\n' "$tgt"
    else
        printf '  BROKEN memory: dangling link -> %s\n' "$tgt"
        printf '        the root it pointed at is gone. Remove the link and restart:\n'
        printf '        rm %s\n' "$mem"
    fi
elif [ -d "$mem" ]; then
    printf '  OK    memory: owned here (this directory is a memory root)\n'
else
    printf '  EMPTY memory: nothing resolves for this directory\n'
    found=""
    dir="$(dirname "$CWD")"
    while [ -n "$dir" ] && [ "$dir" != "/" ]; do
        case "$dir" in "$HOME" | "$HOME"/*) ;; *) break ;; esac
        [ -d "${PROJECTS}/$(slug_of "$dir")/memory" ] && { found="$dir"; break; }
        [ "$dir" = "$HOME" ] && break
        dir="$(dirname "$dir")"
    done
    if [ -n "$found" ]; then
        printf '        a root DOES exist above, at %s\n' "$found"
        printf '        so the hook did not run. Check it is installed, then restart.\n'
    else
        printf '        and no ancestor has memory either, so there is nothing to\n'
        printf '        inherit. That is correct for an unrelated project. To make\n'
        printf '        this tree a root:  mkdir -p %s\n' "$mem"
    fi
fi

if [ -d "$mem" ]; then
    # -L matters: $mem is usually a symlink, and without it find stops at the
    # link itself and reports an empty store that is actually full.
    n="$(find -L "$mem" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')"
    printf '  files %s\n' "$n"
    [ "$n" = "0" ] && printf '        (resolves, but the store is empty — nothing has been saved yet)\n'
fi

# ── Is the hook actually wired up? ───────────────────────────────────────────
printf '\n'
hooked=no
for f in "${HOME}/.claude/settings.json" "${HOME}/.claude/settings.local.json"; do
    [ -f "$f" ] || continue
    grep -q 'memory-inherit' "$f" 2>/dev/null && { hooked=yes; printf '  OK    hook registered in %s\n' "$(basename "$f")"; }
done
if [ -d "${HOME}/.claude/plugins" ] && grep -rqs 'memory-inherit' "${HOME}/.claude/plugins" 2>/dev/null; then
    hooked=yes
    printf '  OK    hook supplied by the installed plugin\n'
fi
[ "$hooked" = "no" ] && printf '  WARN  no memory-inherit hook found — new directories will not self-heal\n'

# ── Session history, which forks for its own reasons ─────────────────────────
cfg="${HOME}/.remember/config.json"
if [ -f "$cfg" ]; then
    dd="$(sed -n 's/.*"data_dir"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$cfg" | head -1)"
    printf '  OK    .remember data_dir: %s\n' "${dd:-<unset>}"
elif [ -d "${HOME}/.remember" ] || [ -d "./.remember" ]; then
    printf '  WARN  .remember has no user-global config — it defaults to project-relative,\n'
    printf '        so each checkout accumulates a separate history\n'
fi

# ── What the hook has actually been doing ────────────────────────────────────
LOG="${HOME}/.claude/memory-inherit.log"
if [ -f "$LOG" ]; then
    printf '\n  recent links:\n'
    tail -3 "$LOG" | sed 's/^/    /'
fi

printf '\n'
