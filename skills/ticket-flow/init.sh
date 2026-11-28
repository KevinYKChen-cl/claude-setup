#!/usr/bin/env bash
# Set the current git repo up for the Pocock + beads workflow, personal mode:
# beads in stealth mode, personal files kept out of git, CLAUDE.local.md and
# docs/agents/ from the templates. Commits nothing and leaves team files alone.
#   bash ~/.claude/skills/ticket-flow/init.sh
set -e
here="$(cd "$(dirname "$0")" && pwd)"
root="$(git rev-parse --show-toplevel)"
cd "$root"

wanted=(CLAUDE.local.md .beads/ .claude/ docs/agents/ docs/adr/ GLOSSARY.md CONTEXT.md)
# The files this script writes: if the team tracks one of them, writing it would change a team file.
written=(CLAUDE.local.md .beads/ docs/agents/)

# Exclude only works for untracked files. A path the team already tracks is the team's: leave it
# alone and say so. Stop only if the team tracks a file this script would write.
clash="$(git ls-files -- "${written[@]}" | head -5)"
if [ -n "$clash" ]; then
  echo "Stopped: the repo tracks files this setup would write:"
  echo "$clash"
  exit 1
fi
personal=()
for p in "${wanted[@]}"; do
  if [ -n "$(git ls-files -- "$p" | head -1)" ]; then
    echo "skipped: $p is tracked by the repo (the team's); personal files under it would show in git status"
  else
    personal+=("$p")
  fi
done

if [ -d .beads ]; then
  echo "beads: already set up, skipped"
else
  bd init --stealth --non-interactive --quiet
  echo "beads: initialised in stealth mode"
fi

exclude="$(git rev-parse --git-path info/exclude)"
mkdir -p "$(dirname "$exclude")"
touch "$exclude"
added=0
for p in "${personal[@]}"; do
  if ! grep -qxF "$p" "$exclude"; then
    [ $added = 0 ] && printf '\n# Personal workflow files (ticket-flow)\n' >> "$exclude"
    echo "$p" >> "$exclude"
    added=$((added + 1))
  fi
done
echo "exclude: $added path(s) added"

if [ ! -f CLAUDE.local.md ]; then
  cp "$here/templates/CLAUDE.local.md" CLAUDE.local.md
  echo "CLAUDE.local.md: created"
elif grep -q "<!-- ticket-flow -->" CLAUDE.local.md; then
  echo "CLAUDE.local.md: already set up, skipped"
else
  printf '\n' >> CLAUDE.local.md
  cat "$here/templates/CLAUDE.local.md" >> CLAUDE.local.md
  echo "CLAUDE.local.md: workflow section appended"
fi

mkdir -p docs/agents
for f in issue-tracker.md domain.md; do
  if [ -f "docs/agents/$f" ]; then
    echo "docs/agents/$f: exists, left as is"
  else
    cp "$here/templates/docs/agents/$f" "docs/agents/$f"
    echo "docs/agents/$f: created"
  fi
done

echo "git status (should show none of the files above):"
git status --short
