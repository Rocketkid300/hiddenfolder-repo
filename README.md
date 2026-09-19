# 📦 Big Pickle Repo — Hidden Folder

A Sileo-compatible repo hosting **Hidden Folder** — a Dopamine (rootless, iOS 15–16)
tweak that adds a passcode-protected *Hidden* folder at the end of the App Library.

```
repo/
├── build.sh          # bootstrap Theos + build tweak + refresh the repo (one-shot)
├── make-repo.sh      # regenerate Packages/Release from the .debs in debs/
└── debs/             # compiled .deb packages (built by build.sh)
```

## Add to Sileo (GitHub Pages — live now)

Our repo is published at:

```
https://rocketkid300.github.io/hiddenfolder-repo/
```

**Sileo → Sources → ⨁ → Add Source** → paste the URL above → **Add Anyway** on the unsigned warning → install **Hidden Folder**.

## Using the tweak (no Settings page needed)

Everything lives inside the folder itself:

1. Open the **App Library** → tap the 🔒 **Hidden** pod at the end.
2. Tap the **⚙️ gear** (top-left) → **Set Passcode** → enter a 4-digit code twice.
3. Flip the **Hide Mode** switch ON.
4. **Hide:** tap any Home Screen app once (while Hide Mode is on).
5. **Unhide:** long-press an app inside the Hidden folder.
6. **Change/remove passcode, lock, or how-it-works:** ⚙️ gear inside the folder.

Dependencies: `mobilesubstrate` (ElleKit on Dopamine) and `oldabi` (arm64e devices;
if Sileo asks to add **ellekit.space** to resolve it, accept — it's the standard Dopamine repo).

## Local building / hosting (optional)

```
repo/
├── build.sh          # bootstrap Theos + build tweak + refresh the repo (one-shot)
├── make-repo.sh      # regenerate Packages/Release from the .debs in debs/
├── publish-github.sh # push repo/ to GitHub Pages (needs `gh` authed)
└── debs/             # compiled .deb packages (built by build.sh)
```

Serve locally for testing:
```bash
cd repo && python3 -m http.server 8080   # then add http://<your-lan-ip>:8080 in Sileo
```

Rebuild + republish after code changes:
```bash
./repo/build.sh && ./repo/publish-github.sh
```

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