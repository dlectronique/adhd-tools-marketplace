# memory-inherit — a Claude Code plugin

*Your memory isn't missing. It's in a directory Claude isn't looking at.*

## The problem

Claude Code keeps auto-memory in `~/.claude/projects/<cwd-slug>/memory/`, where
the slug is your **exact** working directory with `/`, `.` and `_` turned into
`-`:

```
/Users/you/code/app                          -> -Users-you-code-app
/Users/you/code/app/.claude/worktrees/fix-3  -> -Users-you-code-app--claude-worktrees-fix-3
```

Those are different keys, so they are different stores. Open a session in a
git worktree, or one directory down from where your memory was written, and
Claude sees **nothing** — no warning, no error, just a model that has
apparently forgotten everything you told it.

The store is laid out like a hierarchy. It does not inherit like one.

This is easy to miss for a long time. In the estate this plugin was written
for, one repo had accumulated **289 session transcripts and no `memory/`
directory at all** — every session started in that repo had run blind.

## What it does

On session start, walk up from the current directory. The first ancestor that
owns a real `memory/` directory becomes the memory root, and the current
directory is symlinked at it.

```
~/code/                 <- memory lives here
  app/                  <- inherits
    .claude/worktrees/
      fix-3/            <- inherits
      spike/            <- inherits, the moment it exists
```

A tree opts in simply by **having memory at its root**. There is no config
file, no list of paths, and nothing to update as worktrees come and go.

## Install

```
/plugin marketplace add dlectronique/adhd-tools-marketplace
/plugin install memory-inherit@adhd-tools
```

Then start a new session. Installing is the entire setup — the plugin brings
its own hook, so there is no `settings.json` to hand-edit.

> `/plugin` exists in the terminal `claude` CLI, not the editor extension.

To check it worked, from any subdirectory:

```
/memory-doctor
```

## Making a directory a memory root

Only if you don't have one yet. Memory has to exist *somewhere* before
anything can inherit it — the plugin links to a root, it doesn't invent one.

```sh
mkdir -p ~/.claude/projects/"$(printf '%s' ~/code | tr '/._' '---')"/memory
```

Everything under `~/code` inherits from the next session onward. Put the root
at whatever level you want shared: one repo, or a whole tree of them.

## Safety

A hook that runs at every session start has to be boring. This one:

- **Never overwrites** an existing `memory/` entry, real directory or symlink.
  A directory that owns memory keeps it.
- **Never climbs above `$HOME`.**
- **Resolves one symlink hop**, so links point at the real store instead of
  chaining. Chains break as soon as a middle link is cleaned up.
- **Always exits 0.** A memory link is never worth breaking a session over.
- **Prints nothing on stdout.** `SessionStart` stdout is injected into the
  model's context, so a chatty hook is a permanent tax on every session.
  Diagnostics go to `~/.claude/memory-inherit.log`.

## `/memory-doctor`

A read-only report: whether memory resolves here and from where, how many
files are in it, whether the hook is wired up, and how `.remember` is
configured if you use it.

It distinguishes **"no root above, which is correct for this project"** from
**"a root exists but the hook didn't run"** — those look identical from the
outside and need opposite responses.

## A related trap: `.remember`

If you use the `remember` plugin, its `data_dir` defaults to
`.remember` **project-relative**. Current versions resolve a git worktree back
to its main checkout, so worktrees share a store — but two separate checkouts
still get separate histories, and nothing tells you when that happens.

For one shared timeline across everything, set an absolute path in
`~/.remember/config.json`:

```json
{ "data_dir": "/Users/you/code/.remember" }
```

For per-project stores that still stay shared across each project's worktrees,
use `{slug}` — it is computed from the main checkout, not from cwd:

```json
{ "data_dir": "~/.remember/{slug}" }
```

Point it at a store that **already holds your history** if you have one, so
there is nothing to migrate.

## Tests

```sh
./tests/test-memory-inherit.sh
```

16 cases, each against a throwaway `$HOME` so the suite never touches a real
memory estate.

## Licence

MIT, same as the rest of this marketplace.
