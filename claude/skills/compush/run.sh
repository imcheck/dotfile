#!/bin/bash
# compush — commit and push in one shot.
# Called by the compush SKILL.md via Claude Code.
#
# Usage:
#   ./claude/skills/compush/run.sh [--all] -m "commit message"
#
# Options:
#   --all    Stage all changes (git add -A) before committing
#   -m MSG   Commit message (required)

set -euo pipefail

STAGE_ALL=false
MESSAGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      STAGE_ALL=true
      shift
      ;;
    -m)
      MESSAGE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$MESSAGE" ]]; then
  echo "Error: commit message required (-m \"message\")" >&2
  exit 1
fi

# Stage if requested
if [[ "$STAGE_ALL" == true ]]; then
  git add -A
  echo "Staged all changes."
fi

# Commit
git commit -m "$MESSAGE"
echo "Committed."

# Push (set upstream if needed)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if git rev-parse --verify "origin/$BRANCH" &>/dev/null; then
  git push
else
  git push --set-upstream origin "$BRANCH"
fi
echo "Pushed to origin/$BRANCH."

# Summary
echo ""
echo "=== Summary ==="
echo "Branch: $BRANCH"
echo "Commit: $(git rev-parse --short HEAD)"
echo "Message: $MESSAGE"
echo "Files changed: $(git diff --stat HEAD~1 HEAD | tail -1)"
