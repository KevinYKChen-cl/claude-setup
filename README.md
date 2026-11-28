# claude-setup

My Claude Code setup for Windows: global rules, the `ticket-flow` and `code-tour` skills, the ticket workflow built on Pocock skills, beads and the Scotty board, and archify for `code-tour`. One script installs all of it.

## Install on a new machine

You need Git, Node.js 20 or newer, and Claude Code. If this repo is private, log in to GitHub CLI first (`gh auth login`).

```powershell
git clone <this repo's URL> $HOME\claude-setup
powershell -ExecutionPolicy Bypass -File $HOME\claude-setup\install.ps1
```

Then open a new terminal and start a new Claude Code session.

The script installs only `main` as it is on GitHub: it stops on another branch, with uncommitted changes, or when `main` is behind `origin/main`. It also stops if an installed copy in `~/.claude` was edited in place, and names the files (see [Update](#update)).

### If you are an agent asked to install this

1. Clone this repo to `~/claude-setup` (`gh repo clone` for a private repo). If it is already there, run `git pull` in it.
2. Run `powershell -ExecutionPolicy Bypass -File ~/claude-setup/install.ps1`. It is safe to run again: finished parts are skipped.
3. If it stops, tell the user why, as it printed:
   - a missing tool: which one, and the `winget` command it printed. Run it again after the user has installed it.
   - not on `main`, uncommitted changes, or behind `origin/main`: ask the user before switching branches or pulling.
   - installed copies edited in place: list the files and ask the user. Don't pass `-OverwriteLocalEdits` on your own.
   - Scotty is running: ask the user to close the board.
4. Check the result in a new terminal:
   - `bd version` prints `1.3.4`.
   - `~/.claude/skills/` has `ticket-flow`, `code-tour`, `archify` and the 11 Pocock skills listed below.
   - `~/.claude/skills/archify/SKILL.md` contains `disable-model-invocation: true`, and `~/.claude/skills/ARCHIFY_VERSION.txt` names the version at the top of `install.ps1`.
   - `~/.local/bin/scotty.cmd` exists.
   - `~/.claude/claude-setup.json` names this clone and the commit installed.
5. Tell the user what was installed and what was skipped, and pass on any warning it printed (for example Scotty's Next.js security reminder).

Don't change the versions in `install.ps1` unless the user asks.

## Update

- Get the latest setup: `git pull`, then run `install.ps1` again.
- Change the global rules or a skill: edit it in this repo on a branch and open a pull request ([AGENTS.md](AGENTS.md) has the steps). After it is merged, pull and install on each machine. `main` accepts changes only through pull requests.
- Never edit the copies in `~/.claude`. If one was edited anyway, `install.ps1` stops and names it: move the edit into this repo, or run again with `-OverwriteLocalEdits` to discard it (the old copies go to `~/.claude/backups/`).
- Try a branch before merging: `install.ps1 -AllowUnmerged` on this machine, or `-TestRoot <folder>` to leave `~/.claude` alone.
- Upgrade Pocock, beads or Scotty: change the version at the top of `install.ps1`. For beads, also put the new zip's SHA-256 from the release's `checksums.txt`.
- Scotty v0.4.0 pins Next.js 16.4.1, which Next.js reports as having a known security vulnerability. Its first build stops with a reminder; `install.ps1` builds once more, as Next.js allows, and prints a warning. The board listens only on 127.0.0.1. Upgrade Scotty when a release with a fixed Next.js is out.
- Upgrade archify: put the new release's version and the SHA-256 of its `archify.zip` at the top of `install.ps1`, run it, then run `/code-tour` on a repo you have toured before and compare. `code-tour` was written against the version pinned there; a newer archify may rename a field or command it uses.

## What gets installed

| What | Where | Version |
|---|---|---|
| Global rules (`CLAUDE.md`) | `~/.claude/CLAUDE.md` | this repo |
| `ticket-flow` skill | `~/.claude/skills/ticket-flow/` | this repo |
| `code-tour` skill | `~/.claude/skills/code-tour/` | this repo |
| Install record | `~/.claude/claude-setup.json`: where this clone is, and the commit installed | written by `install.ps1` |
| Pocock skills | `~/.claude/skills/<name>/` | mattpocock/skills `4ae2317` (2026-10-31) |
| archify | `~/.claude/skills/archify/`, manual only (`disable-model-invocation: true`) | v3.3.2, SHA-256 checked |
| beads (`bd`) | `~/.local/bin/bd.exe` | v1.3.4, SHA-256 checked |
| Scotty board | `%LOCALAPPDATA%\Programs\bead-me-up-scotty\`, started with `~/.local/bin/scotty.cmd` | v0.4.0, usage reporting off |

The 11 Pocock skills: `setup-matt-pocock-skills`, `grill-with-docs`, `grilling`, `domain-modeling`, `to-spec`, `to-tickets`, `implement-spec`, `implement`, `tdd`, `code-review`, `codebase-design`.

`~/.local/bin` is added to your user PATH if it isn't there yet.

## Using the workflow

- In a repo, type `/ticket-flow` in Claude Code. The first time, it sets the repo up in personal mode: tickets stay on your machine and nothing is committed to the team's repo. After that, it tells you which step you are at and the exact command to type next.
- Type `scotty` in a terminal at the repo root to open the board at http://127.0.0.1:3197.
- Type `/code-tour repo <path>` to get one clickable page that explains how a repo works: a source-backed overview that drills down into sequence diagrams, with a story that shows the key code. `/code-tour pr <branch> [base]` explains what a branch or pull request changed, with a before-and-after diff.
- archify loads only when `code-tour` uses it or you type `/archify`, so its long description stays out of every session.

## Not in this repo

Login credentials, Claude's memory folders and plugin caches stay on each machine.
