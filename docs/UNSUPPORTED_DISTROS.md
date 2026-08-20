# Unsupported Distros

These distros are not directly supported by `install-dist.sh`. They may work with manual intervention or by using the fallback precompiled download.

## Detection logic

`install-dist.sh` detects distros via `ID` and `ID_LIKE` fields from `/etc/os-release`. Derivative distros are automatically mapped to their parent family.

## Supported families

| Family | Detects via `ID` / `ID_LIKE` | Packages |
|--------|------------------------------|----------|
| Fedora | `fedora`, `rhel`, `centos`, `rocky`, `alma`, `nobara` | `gcc-c++ cmake qt6-qtbase-devel qt6-qtdeclarative-devel fontconfig-devel zlib-devel` |
| Debian | `debian`, `ubuntu`, `linuxmint`, `pop`, `kdeaneon`, `zorin`, `elementary`, `raspbian` | `g++ cmake qt6-base-dev qt6-declarative-dev libfontconfig1-dev zlib1g-dev` |
| Arch | `arch`, `manjaro`, `endeavouros`, `cachyos`, `garuda`, `artix` | `gcc cmake qt6-base qt6-declarative fontconfig zlib` |
| SUSE | `suse`, `opensuse`, `sles` | `gcc-c++ cmake libQt6Core-devel libQt6Qml-devel fontconfig-devel zlib-devel` |

## Unsupported distros

| Distro | `ID` | `ID_LIKE` | Package manager | Status |
|--------|------|-----------|-----------------|--------|
| Void Linux | `void` | — | xbps | No Qt6 packages in main repos |
| Gentoo | `gentoo` | — | emerge | Manual build possible |
| NixOS | `nixos` | — | nix | Different paradigm, manual build needed |
| Alpine | `alpine` | — | apk | Minimal Qt6 support |
| Solus | `solus` | — | eopkg | Limited Qt6 packages |
| Clear Linux | `clear-linux-os` | — | swupd | Intel-oriented, limited Qt6 |
| Slackware | `slackware` | — | installpkg | Manual dependency management |
| Puppy Linux | `puppy` | — | pkg | Minimal, no Qt6 dev packages |

## How to install on unsupported distros

1. Install manually: C++ compiler, cmake (optional), Qt6 dev headers, fontconfig dev, zlib dev
2. Clone the repo: `git clone https://github.com/YoannDev90/KDE-Modern-reClock`
3. Run: `bash scripts/install-common.sh`

Or use the one-liner which will attempt the precompiled download as fallback:
```bash
sh -c "$(curl -fsSL https://github.com/YoannDev90/KDE-Modern-reClock/releases/latest/download/install-dist.sh)"
```
