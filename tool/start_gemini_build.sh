#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v gemini >/dev/null 2>&1; then
  echo "Gemini CLI not found. Install with: npm install -g @google/gemini-cli@latest" >&2
  exit 127
fi

exec gemini -i "$(cat GEMINI_BUILD_MASTER_PROMPT.md)"
