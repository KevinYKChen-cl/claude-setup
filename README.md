# claude-setup

My Claude Code setup for Windows: global rules, the `ticket-flow` skill, and the ticket workflow built on Pocock skills, beads and the Scotty board. One script installs all of it.

## Install on a new machine

You need Git, Node.js 20 or newer, and Claude Code. If this repo is private, log in to GitHub CLI first (`gh auth login`).

```powershell
git clone <this repo's URL> $HOME\claude-setup
powershell -ExecutionPolicy Bypass -File $HOME\claude-setup\install.ps1
```

Then open a new terminal and start a new Claude Code session.

### If you are an agent asked to install this

1. Clone this repo to `~/claude-setup` (`gh repo clone` for a private repo). If it is already there, run `git pull` in it.
2. Run `powershell -ExecutionPolicy Bypass -File ~/claude-setup/install.ps1`. It is safe to run again: finished parts are skipped.
3. If it stops because a tool is missing, tell the user which one and the `winget` command it printed. Run it again after the user has installed it.
4. Check the result in a new terminal:
   - `bd version` prints `1.3.4`.
   - `~/.claude/skills/` has `ticket-flow` and the 11 Pocock skills listed below.
   - `~/.local/bin/scotty.cmd` exists.
5. Tell the user what was installed and what was skipped. If the script backed up an old `~/.claude/CLAUDE.md` (`CLAUDE.md.bak-<time>`), say so, so they can compare.

Don't change the versions in `install.ps1` unless the user asks.

## Update

- Get the latest setup: `git pull`, then run `install.ps1` again.
- Change the global rules or `ticket-flow`: edit them in this repo, commit and push, then pull and install on each machine. Don't edit the copies in `~/.claude`; the next install overwrites them.
- Upgrade Pocock, beads or Scotty: change the version at the top of `install.ps1`. For beads, also put the new zip's SHA-256 from the release's `checksums.txt`.

## What gets installed

| What | Where | Version |
|---|---|---|
| Global rules (`CLAUDE.md`) | `~/.claude/CLAUDE.md` | this repo |
| `ticket-flow` skill | `~/.claude/skills/ticket-flow/` | this repo |
| Pocock skills | `~/.claude/skills/<name>/` | mattpocock/skills `4ae2317` (2026-10-31) |
| beads (`bd`) | `~/.local/bin/bd.exe` | v1.3.4, SHA-256 checked |
| Scotty board | `%LOCALAPPDATA%\Programs\bead-me-up-scotty\`, started with `~/.local/bin/scotty.cmd` | v0.4.0, usage reporting off |

The 11 Pocock skills: `setup-matt-pocock-skills`, `grill-with-docs`, `grilling`, `domain-modeling`, `to-spec`, `to-tickets`, `implement-spec`, `implement`, `tdd`, `code-review`, `codebase-design`.

`~/.local/bin` is added to your user PATH if it isn't there yet.

## Using the workflow

- In a repo, type `/ticket-flow` in Claude Code. The first time, it sets the repo up in personal mode: tickets stay on your machine and nothing is committed to the team's repo. After that, it tells you which step you are at and the exact command to type next.
- Type `scotty` in a terminal at the repo root to open the board at http://127.0.0.1:3197.

## Not in this repo

Login credentials, Claude's memory folders and plugin caches stay on each machine.
