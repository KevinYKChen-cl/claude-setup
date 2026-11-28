# Working in this repo

This repo is the source of my Claude Code setup: `CLAUDE.md`, the skills in `skills/`, and `install.ps1`, which
copies them into `~/.claude`. The files in `~/.claude` are installed copies. Change them here, never there:
`install.ps1` refuses to replace a copy that was edited in place.

## Changing anything

1. Start a branch from an up-to-date main: `git fetch`, then `git switch -c <topic> origin/main`. Never commit to
   main. GitHub rejects direct pushes to it; every change goes in through a pull request.
2. Commit, push the branch and open a pull request with `gh pr create`. Never merge it and never turn on
   auto-merge. I review it and merge it.
3. Write the pull request title and description in Traditional Chinese, and keep them short:
   - what changed and why, in a few lines
   - anything I must do after merging, such as running `install.ps1` again or restarting something

   This is an exception to my global rule that text in a repo stays English. Commit messages, code, comments and
   files stay English.
4. Put archify diagrams in the pull request so I can follow the change without reading every line.
   - Make a PR pack as `skills/code-tour/SKILL.md` and its `references/pr.md` describe. Read those files directly:
     the skill is manual-only.
   - Attach the pack to the description with `archify pr attach <pr> --manifest <out>/pr-pack.receipt.json --target body`,
     after a `--dry-run`. It replaces only its own block, so the Chinese text you wrote stays.
   - If a change has nothing to draw (wording only), say so in the description instead.
5. After I merge, `git switch main`, `git pull`, and run `install.ps1` on every machine that should get it.

## Testing a change before it is merged

`install.ps1` installs only main as it is on GitHub. To try a branch:

- on this machine, run it with `-AllowUnmerged`
- in a scratch folder, run it with `-TestRoot <folder>`, which leaves `~/.claude` alone

Pinned versions (Pocock, beads, Scotty, archify) change only when I ask.
