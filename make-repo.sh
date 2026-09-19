#!/usr/bin/env bash
# make-repo.sh — regenerate Packages / Packages.gz / Packages.bz2 / Release
# for every .deb already present in repo/debs/. Run after adding new debs.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$REPO/debs"

# Prefer a locally-bootstrapped dpkg (see build.sh) when none is installed system-wide.
if ! command -v dpkg-deb >/dev/null 2>&1 && [[ -x "$REPO/../tools/dpkg-root/usr/bin/dpkg-deb" ]]; then
  export PATH="$REPO/../tools/dpkg-root/usr/bin:$PATH"
  export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}:$REPO/../tools/dpkg-root/usr/lib"
fi

cd "$REPO"

rm -f Packages Packages.gz Packages.bz2 Release Release.gpg InRelease

: > Packages
for deb in debs/*.deb; do
  [ -e "$deb" ] || continue
  echo ">> indexing $deb"
  {
    echo "Package: $(dpkg-deb -f "$deb" Package)"
    echo "Version: $(dpkg-deb -f "$deb" Version)"
    echo "Architecture: $(dpkg-deb -f "$deb" Architecture)"
    echo "Maintainer: $(dpkg-deb -f "$deb" Maintainer)"
    echo "Section: $(dpkg-deb -f "$deb" Section)"
    echo "Description: $(dpkg-deb -f "$deb" Description)"
    echo "Filename: $deb"
    echo "Size: $(stat -c%s "$deb")"
    echo "MD5sum: $(md5sum "$deb" | cut -d' ' -f1)"
    echo "SHA1: $(sha1sum "$deb" | cut -d' ' -f1)"
    echo "SHA256: $(sha256sum "$deb" | cut -d' ' -f1)"
    echo
  } >> Packages
done

gzip -c9 Packages > Packages.gz
bzip2 -c Packages > Packages.bz2

{
  echo "Origin: Big Pickle Repo"
  echo "Label: Big Pickle Repo"
  echo "Suite: stable"
  echo "Version: 1.0"
  echo "Codename: stable"
  echo "Architectures: iphoneos-arm64"
  echo "Components: main"
  echo "Description: Hidden Folder tweak for Dopamine (iOS 15-16, rootless)"
  echo "Date: $(date -R)"
  echo "MD5Sum:"
  echo " $(md5sum Packages | cut -d' ' -f1) $(stat -c%s Packages) Packages"
  echo " $(md5sum Packages.gz | cut -d' ' -f1) $(stat -c%s Packages.gz) Packages.gz"
  echo " $(md5sum Packages.bz2 | cut -d' ' -f1) $(stat -c%s Packages.bz2) Packages.bz2"
  echo "SHA1:"
  echo " $(sha1sum Packages | cut -d' ' -f1) $(stat -c%s Packages) Packages"
  echo " $(sha1sum Packages.gz | cut -d' ' -f1) $(stat -c%s Packages.gz) Packages.gz"
  echo " $(sha1sum Packages.bz2 | cut -d' ' -f1) $(stat -c%s Packages.bz2) Packages.bz2"
  echo "SHA256:"
  echo " $(sha256sum Packages | cut -d' ' -f1) $(stat -c%s Packages) Packages"
  echo " $(sha256sum Packages.gz | cut -d' ' -f1) $(stat -c%s Packages.gz) Packages.gz"
  echo " $(sha256sum Packages.bz2 | cut -d' ' -f1) $(stat -c%s Packages.bz2) Packages.bz2"
} > Release

# Optional: sign the Release (set REPO_GPG_KEY=<key id> to enable).
if [[ -n "${REPO_GPG_KEY:-}" ]] && command -v gpg >/dev/null 2>&1; then
  gpg --default-key "$REPO_GPG_KEY" --clearsign -o Release.gpg Release
  gpg --default-key "$REPO_GPG_KEY" -abs -o InRelease Release
  echo ">> Signed Release with key $REPO_GPG_KEY"
else
  echo ">> Unsigned repo (fine for Sileo; it shows a one-time warning)."
  echo "   To sign: REPO_GPG_KEY=<your key id> $0"
fi

echo ">> Repo ready at $REPO"
echo ">> Serve: cd $REPO && python3 -m http.server 8080"