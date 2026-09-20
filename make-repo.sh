#!/usr/bin/env bash
# make-repo.sh — compatibility wrapper around the canonical repo indexer.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ ! -x "$ROOT/repo/gen-index.sh" ]]; then
  echo "!! missing repo/gen-index.sh" >&2
  exit 1
fi
bash "$ROOT/repo/gen-index.sh"
