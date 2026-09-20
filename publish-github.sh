#!/usr/bin/env bash
# publish-github.sh — push the Sileo repo (repo/ contents) to GitHub Pages.
#
# Requirements: gh CLI installed + authenticated once (`gh auth login`).
# Usage:  ./repo/publish-github.sh [repo-name]     (default: hiddenfolder-repo)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_SRC="$ROOT/repo"
TARGET="${1:-hiddenfolder-repo}"

# Always rebuild Packages/Release + GPG signatures from disk before push.
# Publishing without this is how Sileo got a stale/unsigned Release.
bash "$ROOT/repo/gen-index.sh"

command -v gh >/dev/null 2>&1 || { echo "!! Install gh (https://cli.github.com) first." >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "!! Run 'gh auth login' first." >&2; exit 1; }
USER="$(gh api user -q .login)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if gh repo view "$USER/$TARGET" >/dev/null 2>&1; then
  # Update: clone the live repo, overlay new content, commit, push.
  echo ">> Repo $USER/$TARGET exists — updating…"
  gh repo clone "$USER/$TARGET" "$TMP" >/dev/null
  rsync -a --delete --exclude .git "$REPO_SRC/./" "$TMP/"
  cd "$TMP"
  git add -A
  git -c user.email="sileo@github" -c user.name="sileo-repo" \
      commit -qm "Sileo repo update $(date -u +%F)" || true
  git push
else
  # First publish: create the repo from a fresh copy of repo/ contents.
  cp -r "$REPO_SRC"/. "$TMP"/
  cd "$TMP"
  git init -q
  git add -A
  git -c user.email="sileo@github" -c user.name="sileo-repo" \
      commit -qm "Sileo repo initial publish $(date -u +%F)"
  gh repo create "$TARGET" --public \
    --description "Hidden Folder tweak for Dopamine (rootless) — Sileo repo" \
    --source "$TMP" --remote origin --push
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# Ensure GitHub Pages serves from the default branch root.
if ! gh api "repos/$USER/$TARGET/pages" -X POST \
     -f "source[branch]=$BRANCH" -f "source[path]=/"; then
  echo ">> Pages is already configured (first build takes ~1 min)."
fi

echo
echo "=============================================================="
echo "  Your Sileo repo URL (add this in Sileo → Sources → +):"
echo "    https://$USER.github.io/$TARGET/"
echo "=============================================================="
echo "  Updates take ~1 minute to appear on GitHub Pages."
echo "  Rebuild + re-publish after changes:  ./repo/build.sh && ./repo/publish-github.sh"