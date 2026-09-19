#!/usr/bin/env bash
# build.sh — one-shot build of the Hidden Folder tweak + Sileo repo refresh.
#
#   ./repo/build.sh                 # builds and regenerates Packages/Release
#   THEOS_SDK_URL=... ./repo/build.sh
#
# First run bootstraps everything into <repo root>/.theos:
#   Theos (git clone) + iOS SDK + the Linux iOS toolchain + a local ldid.
# If dpkg-deb is not installed system-wide, a local copy is unpacked into tools/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$ROOT/repo"
mkdir -p "$REPO/debs"

ARCH="$(uname -m)"

# --- 0. dpkg-deb (needed to build .deb archives) -----------------------------
if ! command -v dpkg-deb >/dev/null 2>&1; then
  if command -v pacman >/dev/null 2>&1; then
    echo ">> dpkg-deb not found — unpacking a local copy from Arch's repo into tools/ ..."
    if [[ ! -x "$ROOT/tools/dpkg-root/usr/bin/dpkg-deb" ]]; then
      DPKG_JSON="$(curl -sSL "https://archlinux.org/packages/search/json/?name=dpkg")"
      FILENAME="$(printf '%s' "$DPKG_JSON" | python3 -c "
import json,sys
d=json.load(sys.stdin)
hits=[r for r in d.get('results',[]) if r.get('arch')==sys.argv[1] and r.get('repo') in ('core','extra')]
sys.stdout.write(hits[0]['filename'] if hits else '')" "$ARCH")"
      [[ -n "$FILENAME" ]] || { echo "!! Could not resolve dpkg package name for $ARCH." >&2; exit 1; }
      mkdir -p "$ROOT/tools/dpkg-root"
      curl -sSL -o /tmp/dpkg.pkg.tar.zst "https://geo.mirror.pkgbuild.com/core/os/$ARCH/$FILENAME" \
        || curl -sSL -o /tmp/dpkg.pkg.tar.zst "https://geo.mirror.pkgbuild.com/extra/os/$ARCH/$FILENAME"
      tar --zstd -xf /tmp/dpkg.pkg.tar.zst -C "$ROOT/tools/dpkg-root"
      rm -f /tmp/dpkg.pkg.tar.zst
    fi
    export PATH="$ROOT/tools/dpkg-root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}:$ROOT/tools/dpkg-root/usr/lib"
  else
    echo "!! dpkg-deb is required but not installed (install the 'dpkg' package)." >&2
    exit 1
  fi
fi

# --- 1. Theos bootstrap (first run only) -----------------------------------
if [[ -z "${THEOS:-}" || ! -d "$THEOS" ]]; then
  if [[ -d "$ROOT/.theos" ]]; then
    export THEOS="$ROOT/.theos"
  else
    echo ">> Bootstrap: cloning Theos into $ROOT/.theos ..."
    git clone --recursive --depth 1 https://github.com/theos/theos.git "$ROOT/.theos"
    export THEOS="$ROOT/.theos"
  fi
fi

# Install the iOS SDK if missing.
if [[ -z "$(ls -d "$THEOS"/sdks/iPhoneOS*.sdk 2>/dev/null || true)" ]]; then
  SDK_URL="${THEOS_SDK_URL:-https://github.com/theos/sdks/releases/download/master-146e41f/iPhoneOS16.5.sdk.tar.xz}"
  echo ">> Downloading iOS SDK from: $SDK_URL"
  mkdir -p "$THEOS/sdks"
  curl -L --fail -o /tmp/iPhoneOS.sdk.tar.xz "$SDK_URL"
  tar -C "$THEOS/sdks" -xJf /tmp/iPhoneOS.sdk.tar.xz
  rm -f /tmp/iPhoneOS.sdk.tar.xz
fi

# Install the Linux iOS toolchain if missing.
if [[ ! -x "$THEOS/toolchain/linux/iphone/bin/clang" ]]; then
  echo ">> Downloading the iOS toolchain (iOSToolchain-$ARCH) ..."
  mkdir -p "$THEOS/toolchain"
  curl -L --fail -o /tmp/iOSToolchain.tar.xz \
    "https://github.com/L1ghtmann/llvm-project/releases/latest/download/iOSToolchain-$ARCH.tar.xz"
  tar -C "$THEOS/toolchain" -xJf /tmp/iOSToolchain.tar.xz
  rm -f /tmp/iOSToolchain.tar.xz
fi

# Provide ldid for code signing (Theos expects $THEOS/bin/ldid on Linux).
if [[ ! -x "$THEOS/bin/ldid" ]]; then
  echo ">> Building ldid ..."
  TMP_LDID="$(mktemp -d)"
  git clone --depth 1 https://github.com/xerub/ldid.git "$TMP_LDID/ldid" >/dev/null 2>&1
  (cd "$TMP_LDID/ldid" && make >/dev/null 2>&1)
  cp "$TMP_LDID/ldid/ldid" "$THEOS/bin/ldid"
  chmod +x "$THEOS/bin/ldid"
  rm -rf "$TMP_LDID"
fi

# --- 2. Build ----------------------------------------------------------------
cd "$ROOT"
make clean >/dev/null 2>&1 || true
make package FINALPACKAGE=1

# Locate the freshest deb produced by this build.
DEB="$(find "$ROOT" -maxdepth 3 -name '*.deb' -newer "$ROOT/Makefile" 2>/dev/null | sort | tail -n 1)"
if [[ -z "$DEB" ]]; then
  DEB="$(ls -t "$ROOT"/*.deb "$ROOT"/packages/*.deb "$ROOT"/.theos/_/debs/*.deb 2>/dev/null | head -n 1 || true)"
fi
if [[ -z "$DEB" ]]; then
  echo "!! Build finished but no .deb found." >&2
  exit 1
fi

echo ">> Built: $DEB"

# --- 3. Add to repo + regenerate metadata ------------------------------------
cp -f "$DEB" "$REPO/debs/"
"$REPO/make-repo.sh"

echo ""
echo ">> Done. Your repo is at: $REPO"
echo ">> Serve it so Sileo can install the tweak:"
echo "     cd $REPO && python3 -m http.server 8080"
echo ">> Then on your iPhone (same Wi-Fi) add this repo to Sileo:"
echo "     http://<YOUR-COMPUTER-IP>:8080"