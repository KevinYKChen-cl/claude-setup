<!-- ticket-flow -->
# Personal workflow (only on my machine)

This repo may be shared with a team. My ticket tracking and workflow files stay local.

- Tickets live in beads (`bd`, stealth mode). Use `bd ready`, `bd show <id>`, `bd create ... --parent <id>`, `bd dep add <issue> <depends-on>`. Claim a ticket with `bd update <id> --claim` when work on it starts; close it with `bd close <id>` once it is merged into the integration branch.
- Personal files are listed in `.git/info/exclude`: `CLAUDE.local.md`, `.beads/`, `.claude/`, `docs/agents/`, `docs/adr/`, `GLOSSARY.md`, `CONTEXT.md`. Never commit them, never force-add them, and never edit the team's `CLAUDE.md` for this workflow; put workflow config in this file instead.
- Git for the code itself (branches, worktrees, commits, merges) works as usual.
- Don't run `bd prime`: in stealth mode it says "no git ops", which conflicts with `/implement-spec`.

## Agent skills

### Issue tracker

Issues and specs live in beads (`bd`, stealth mode, local only); specs are epics, tickets are their children, blocking uses `bd dep`. See `docs/agents/issue-tracker.md`.

### Domain docs

Single-context: `GLOSSARY.md` and `docs/adr/` at the repo root (both local only, excluded from git). See `docs/agents/domain.md`.
