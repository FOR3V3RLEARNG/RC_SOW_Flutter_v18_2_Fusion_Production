#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${RC_SOW_REPO_DIR:-$HOME/RC_SOW_Flutter_v18_2_Fusion_Production}"
FEATURE_BRANCH="${FEATURE_BRANCH:-fusion/v20.4-scalable-production}"
PUSH="${PUSH:-0}"

if [ ! -d "$TARGET_DIR/.git" ]; then
  echo "ERROR: Git repository not found at $TARGET_DIR" >&2
  echo "Set RC_SOW_REPO_DIR=/path/to/repository and run again." >&2
  exit 1
fi

cd "$TARGET_DIR"
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ERROR: Working tree is not clean. Commit or stash current work first." >&2
  git status --short
  exit 1
fi

echo "==> Syncing latest main"
git fetch origin
git checkout main
git pull --ff-only origin main

echo "==> Preparing feature branch: $FEATURE_BRANCH"
if git show-ref --verify --quiet "refs/heads/$FEATURE_BRANCH"; then
  git checkout "$FEATURE_BRANCH"
  git rebase main
elif git show-ref --verify --quiet "refs/remotes/origin/$FEATURE_BRANCH"; then
  git checkout -b "$FEATURE_BRANCH" "origin/$FEATURE_BRANCH"
  git rebase main
else
  git checkout -b "$FEATURE_BRANCH"
fi

echo "==> Overlaying RC SOW v20.4 scalable production source"
rsync -a "$SOURCE_DIR/" "$TARGET_DIR/" \
  --exclude '.git/' \
  --exclude '.dart_tool/' \
  --exclude 'build/' \
  --exclude 'factory_output/' \
  --exclude 'logs/' \
  --exclude 'coverage/' \
  --exclude 'INSTALL_TO_EXISTING_REPO.sh'

# Never package beneficiary assessment workbooks into application assets.
find assets -type f -iname '*Shelter*Assessment*.xlsx' -delete 2>/dev/null || true

# Lightweight checks only. GitHub remains the authoritative Flutter/Dart gate.
python3 scripts/ci/verify_production_contracts.py
git diff --check
git add .
if git diff --cached --quiet; then
  echo "No source changes to commit."
else
  git commit -m "feat: RC SOW v20.4 scalable production architecture"
fi

if [ "$PUSH" = "1" ]; then
  echo "==> Pushing $FEATURE_BRANCH"
  git push -u origin "$FEATURE_BRANCH"
  echo "GitHub Green Gate + Production Factory should now validate this branch."
else
  echo
  echo "Ready on branch: $FEATURE_BRANCH"
  echo "Review with: git status && git log -1 --oneline"
  echo "Push when ready: git push -u origin '$FEATURE_BRANCH'"
fi
