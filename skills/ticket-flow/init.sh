#!/usr/bin/env bash
# Set the current git repo up for the Pocock + beads workflow, personal mode:
# beads in stealth mode, personal files kept out of git, CLAUDE.local.md and
# docs/agents/ from the templates. Commits nothing and leaves team files alone.
#   bash ~/.claude/skills/ticket-flow/init.sh
set -e
here="$(cd "$(dirname "$0")" && pwd)"
root="$(git rev-parse --show-toplevel)"
cd "$root"

personal=(CLAUDE.local.md .beads/ .claude/ docs/agents/ docs/adr/ GLOSSARY.md CONTEXT.md)

# Exclude only works for untracked files: stop if the team already tracks one of them.
tracked="$(git ls-files -- "${personal[@]}" | head -5)"
if [ -n "$tracked" ]; then
  echo "Stopped: these personal paths are already tracked by the repo:"
  echo "$tracked"
  exit 1
fi

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
