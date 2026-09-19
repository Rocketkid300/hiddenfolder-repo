#!/usr/bin/env bash
# publish-github.sh — push the Sileo repo (repo/ contents) to GitHub Pages.
#
# Requirements: gh CLI installed + authenticated once (`gh auth login`).
# Usage:  ./repo/publish-github.sh [repo-name]     (default: hiddenfolder-repo)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_SRC="$ROOT/repo"
TARGET="${1:-hiddenfolder-repo}"

command -v gh >/dev/null 2>&1 || { echo "!! Install gh (https://cli.github.com) first." >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "!! Run 'gh auth login' first." >&2; exit 1; }
USER="$(gh api user -q .login)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cp -r "$REPO_SRC"/. "$TMP"/

cd "$TMP"
git init -q
git add -A
git -c user.email="sileo@github" -c user.name="sileo-repo" commit -qm "Sileo repo update $(date -u +%F)"

# Create the public repo and push the Pages content as its root.
gh repo create "$TARGET" --public \
  --description "Hidden Folder tweak for Dopamine (rootless) — Sileo repo" \
  --source "$TMP" --remote origin --push

# Enable GitHub Pages on the default branch.
BRANCH="$(git -C "$TMP" rev-parse --abbrev-ref HEAD)"
if ! gh api "repos/$USER/$TARGET/pages" -X POST \
     -f "source[branch]=$BRANCH" -f "source[path]=/"; then
  echo ">> Pages may already be enabled or was just created (takes ~1 min the first time)."
fi

echo
echo "=============================================================="
echo "  Your Sileo repo URL (add this in Sileo → Sources → +):"
echo "    https://$USER.github.io/$TARGET/"
echo "=============================================================="
echo "  First update can take ~1 minute to appear on GitHub Pages."
echo "  Rebuild + re-publish after changes:  ./repo/build.sh && ./repo/publish-github.sh"