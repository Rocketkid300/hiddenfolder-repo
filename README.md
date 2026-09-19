# 📦 Big Pickle Repo — Hidden Folder

A Sileo-compatible repo hosting **Hidden Folder** — a Dopamine (rootless, iOS 15–16)
tweak that adds a passcode-protected *Hidden* folder at the end of the App Library.

```
repo/
├── build.sh          # bootstrap Theos + build tweak + refresh the repo (one-shot)
├── make-repo.sh      # regenerate Packages/Release from the .debs in debs/
└── debs/             # compiled .deb packages (built by build.sh)
```

## Add to Sileo

### Option A — local server (fastest to test)

1. Build once:
   ```bash
   ./repo/build.sh
   ```
2. Serve the repo on your network:
   ```bash
   cd repo && python3 -m http.server 8080
   ```
3. Note your computer's LAN IP (`ip addr` or `hostname -I`), e.g. `192.168.1.20`.
4. On your iPhone (same Wi-Fi): **Sileo → Sources → ⨁ → Add Source** →
   ```
   http://192.168.1.20:8080
   ```
5. Install **Hidden Folder** (or `com.bigpickle.hiddenfolder`) → Respring (Sileo does it for you).

### Option B — GitHub Pages (permanent link, shares with friends)

1. Push this folder to GitHub (rename folder to `sileo-repo` for clarity):
   ```bash
   git init && git add -A && git commit -m "Hidden Folder repo" && git branch -M main
   git remote add origin git@github.com:<you>/<repo>.git
   git push -u origin main
   ```
2. GitHub → **Settings → Pages → Branch: main → /root → Save**.
   Make sure a `.nojekyll` file exists at the repo root (included below).
3. Your repo URL becomes:
   ```
   https://<you>.github.io/<repo>/
   ```
   Add that to Sileo.

## Signing (optional)

Sileo accepts unsigned repos (one-time warning). To ship a signed repo:
```bash
gpg --full-generate-key          # once
export REPO_GPG_KEY=<your key id>
./repo/make-repo.sh              # writes Release.gpg + InRelease
```
Sileo can verify with the public key.

## Rebuilding after code changes

```bash
# bump the version in control, then:
./repo/build.sh                  # rebuilds + re-indexes, no re-download of Theos/SDK
```

## Requirements to build

- Linux (Arch/Debian etc.) or macOS
- `git`, `curl`, `clang`, `make`, `dpkg-deb`, `python3`
  - Arch: `sudo pacman -S git curl clang make dpkg python`
- First build downloads Theos + an iOS SDK automatically (a few hundred MB, one time).