#!/usr/bin/env bash
# gen-index.sh — regenerate Packages + Packages.gz for this repo from the debs
# actually on disk, using dpkg-deb -f (deterministic, no Perl, no scanpackages).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$ROOT/repo"
DEBS_DIR="$REPO/debs"
DPKG_DEB="$ROOT/tools/dpkg-root/usr/bin/dpkg-deb"

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

  # Field order per Sileo/Cydia: metadata first (dpkg-deb -f prints the whole control),
  # then Filename/Size/MD5sum appended. Parse only what we MUST reorder; pass through
  # everything else verbatim.
  full="$( "$DPKG_DEB" -f "$deb" 2>/dev/null )" || { echo "!! cannot read control of $deb" >&2; continue; }
  [ -n "$full" ] || continue

  base="$(basename "$deb")"
  size="$(stat -c%s "$deb" 2>/dev/null || stat -f%z "$deb" 2>/dev/null || echo 0)"
  md5="$(md5sum "$deb" 2>/dev/null | awk '{print $1}')"

  {
    echo "$full"
    printf 'Filename: debs/%s\n' "$base"
    printf 'Size: %s\n' "$size"
    printf 'MD5sum: %s\n\n' "$md5"
  } >> "$OUT"
done

gzip -9fk "$OUT" 2>/dev/null || true

echo "=== regenerated from reality ==="
echo "Packages   -> $(wc -c < "$OUT") bytes"
echo "Packages.gz -> $(wc -c < "$OUT.gz" 2>/dev/null || echo '?') bytes"
echo "=== debs indexed: $(grep -c '^Package:' "$OUT") ==="
for v in 1.1.0 1.2.0 1.3.0 1.4.0 1.6.0; do
  line=$(grep -A1 "^Package: com.bigpickle.hiddenfolder$" "$OUT" | grep -m1 "^Version: $v\$" >/dev/null 2>&1 && echo "in index" || echo "ABSENT")
  echo "  $v -> $line"
done
echo "=== 1.6.0 deb block preview ==="
grep -A7 "Package: com.bigpickle.hiddenfolder" "$OUT" | grep -E 'Package:|Version:|Filename:|Size:|MD5sum:' | head -20

# --- Release (Sileo requires it; must match Packages bytes exactly) ---
python3 - <<'PYEOF'
import hashlib, datetime, os
os.chdir(os.path.dirname(os.path.abspath("Packages")) if os.path.exists("Packages") else ".")
files = [f for f in ('Packages', 'Packages.gz') if os.path.exists(f)]
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
