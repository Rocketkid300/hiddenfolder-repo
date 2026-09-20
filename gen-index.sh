#!/usr/bin/env bash
# gen-index.sh — regenerate Packages + Packages.gz + Release, then GPG-sign
# Release.gpg + InRelease, from the debs actually in repo/debs/.
# variants/ is never scanned. Filenames with '+' (disguise builds) are skipped
# even if they leak into debs/, so the Sileo index cannot grow duplicates.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$ROOT/repo"
DEBS_DIR="$REPO/debs"
DPKG_DEB="$ROOT/tools/dpkg-root/usr/bin/dpkg-deb"
GPG_KEY="${REPO_GPG_KEY:-5A92B2C181ED1D23}"

[ -x "$DPKG_DEB" ] || DPKG_DEB="$(command -v dpkg-deb || true)"
if [ -z "$DPKG_DEB" ]; then
  echo "!! no dpkg-deb anywhere" >&2
  exit 1
fi

cd "$REPO"
OUT="$REPO/Packages"
: > "$OUT"

for deb in "$DEBS_DIR"/*.deb; do
  [ -f "$deb" ] || continue

  base="$(basename "$deb")"
  # Disguise variants are versioned like 2.2.1+calculator — never index them.
  case "$base" in
    *+*)
      echo "!! refusing to index variant leaked into debs/: $base" >&2
      continue
      ;;
  esac

  full="$( "$DPKG_DEB" -f "$deb" 2>/dev/null )" || { echo "!! cannot read control of $deb" >&2; continue; }
  [ -n "$full" ] || continue

  size="$(stat -c%s "$deb" 2>/dev/null || stat -f%z "$deb" 2>/dev/null || echo 0)"
  md5="$(md5sum "$deb" 2>/dev/null | awk '{print $1}')"

  {
    echo "$full"
    printf 'Filename: debs/%s\n' "$base"
    printf 'Size: %s\n' "$size"
    printf 'MD5sum: %s\n\n' "$md5"
  } >> "$OUT"
done

# -n: no name/timestamp in the gzip header, so Packages.gz hashes stay
# stable unless Packages itself changed (avoids false "stale Release" diffs).
gzip -9nfk "$OUT"

echo "=== regenerated from reality ==="
echo "Packages   -> $(wc -c < "$OUT") bytes"
echo "Packages.gz -> $(wc -c < "$OUT.gz") bytes"
echo "=== debs indexed: $(grep -c '^Package:' "$OUT" || true) ==="
awk '
  /^Package:/ { pkg=$2 }
  /^Version:/ { ver=$2 }
  /^Filename:/ { print "  " pkg " " ver " -> " $2 }
' "$OUT"

# --- Release (Sileo requires it; hashes must match Packages bytes exactly) ---
python3 - <<'PYEOF'
import hashlib, datetime, os
os.chdir(os.path.dirname(os.path.abspath("Packages")))
files = [f for f in ('Packages', 'Packages.gz') if os.path.exists(f)]
if not files:
    raise SystemExit('!! Packages missing; cannot write Release')
date = datetime.datetime.now(datetime.timezone.utc).strftime('%a, %d %b %Y %H:%M:%S UTC')
lines = ['Origin: HiddenFolder', 'Label: HiddenFolder', 'Suite: stable',
         'Codename: ios', 'Architectures: iphoneos-arm64', 'Components: main',
         'Description: Hidden Folder tweak + Hidden Vault app for Dopamine (rootless)',
         'Date: ' + date]
for algo in ('MD5Sum', 'SHA256'):
    lines.append(algo + ':')
    for f in files:
        data = open(f, 'rb').read()
        h = hashlib.new('md5' if algo == 'MD5Sum' else 'sha256', data).hexdigest()
        lines.append(' %s %16d %s' % (h, len(data), f))
open('Release', 'w').write('\n'.join(lines) + '\n')
print('Release regenerated too')
PYEOF

# --- GPG: InRelease = clearsigned Release; Release.gpg = detached signature ---
# Key is unencrypted (%no-protection). batch + loopback so this never prompts.
if ! command -v gpg >/dev/null 2>&1; then
  echo "!! gpg not found; unsigned Release would be a Sileo hard-block" >&2
  exit 1
fi
rm -f InRelease Release.gpg
gpg --batch --yes --pinentry-mode loopback --default-key "$GPG_KEY" \
    --clearsign --output InRelease Release
gpg --batch --yes --pinentry-mode loopback --default-key "$GPG_KEY" \
    --detach-sign --armor --output Release.gpg Release
echo "=== signed with $GPG_KEY ==="
gpg --batch --verify Release.gpg Release
gpg --batch --verify InRelease
