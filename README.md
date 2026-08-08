<p align="center">
  <img src="https://github.com/YoannDev90/KDE-Modern-reClock/blob/main/assets/logo.jpg" width=100/>
  <h2 align="center">Modern reClock for KDE</h2>
  <p align="center">A modern looking clock widget for KDE Plasma 6!</p>
</p>

<p align="center">
<a href="https://github.com/YoannDev90/KDE-Modern-reClock/actions"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/YoannDev90/KDE-Modern-reClock/ci.yml?branch=main&label=CI&style=for-the-badge&logo=github"></a>
<a href="https://github.com/YoannDev90/KDE-Modern-reClock/releases"><img alt="GitHub release" src="https://img.shields.io/github/v/release/YoannDev90/KDE-Modern-reClock?color=%233DAEE9&style=for-the-badge&logo=github"></a>
<a href="https://github.com/YoannDev90/KDE-Modern-reClock/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/YoannDev90/KDE-Modern-reClock?color=%233DAEE9&style=for-the-badge"></a>
<a href="https://github.com/YoannDev90/KDE-Modern-reClock/network"><img alt="GitHub forks" src="https://img.shields.io/github/forks/YoannDev90/KDE-Modern-reClock?color=%233DAEE9&style=for-the-badge"></a>
<a href="https://github.com/YoannDev90/KDE-Modern-reClock/issues"><img alt="GitHub issues" src="https://img.shields.io/github/issues/YoannDev90/KDE-Modern-reClock?color=%233DAEE9&style=for-the-badge"></a>
<a href="https://github.com/YoannDev90/KDE-Modern-reClock/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/YoannDev90/KDE-Modern-reClock?color=%233DAEE9&style=for-the-badge"></a>
</p>

<p align="center">
  <img src="https://github.com/YoannDev90/KDE-Modern-reClock/blob/main/assets/screenshot.png"/>
</p>

## Features

### Core
- **Auto-scale** — widget content automatically fits its size
- **SDF rendering** — maximum sharpness at any scale
- **Seconds support** — display seconds with `hh:mm:ss`
- **Custom time format** — use any Qt time format (`hh:mm`, `hh:mm:ss AP`, etc.)
- **Custom day/date format** — e.g. `dddd` for full name, `ddd` for abbreviated, `dd MMM yyyy`
- **Uppercase toggle** — capitalize day and date names
- **Bold font toggle** — per-section bold setting for day, date, and time
- **Custom locale** — override system locale for date/time names
- **Language presets** — quick configuration with built-in locale presets
- **Configurable spacing** — adjust spacing between elements
- **C++ timezone plugin** — compiled Qt6/QML plugin for accurate timezone formatting (`formatDateTimeInZone`)

### Custom Text Element
- **Static text** — display any custom message (e.g. "Good Morning", "Today is")
- **Dynamic format** — interpret text as Qt date/time format for live updates (e.g. `HH:mm`, `dddd d MMMM`)
- **Full styling** — separate font, size, spacing, bold, and color settings

### Secondary Timezone
- **Display any IANA timezone** — `America/New_York`, `Asia/Tokyo`, `Europe/Paris`, etc.
- **Timezone selector** — preset list of 40+ major cities, or type a custom IANA ID
- **Label support** — add a short label before the timezone (e.g. "NYC", "Tokyo")
- **Auto-derived format** — timezone format mirrors the main time format (seconds always stripped)
- **DST-aware** — C++ Qt backend with direct `QDateTime::toTimeZone()` conversion for accurate formatting

### Color Modes
Four configurable color modes:
- **Custom** — each element has its own independent color
- **Follow system theme** — text inherits the Plasma theme text color (light/dark)
- **Inverse system theme** — inverted color for maximum contrast on any background
- **Wallpaper-derived** — automatically detects wallpaper brightness and picks white or black text for optimal contrast

### Wallpaper Change Detection
- **Real-time updates** — uses `QFileSystemWatcher` (C++) to detect wallpaper changes instantly
- **No polling** — eliminates the old 5-second timer, reducing CPU usage
- **Auto-adaptation** — color mode switches to wallpaper-based colors when wallpaper changes

### Theming
- **Save/load themes** — save your configuration as named themes
- **Export/import** — share themes as JSON files
- **Per-section reset** — restore individual sections to defaults
- **JSON import/export** — full configuration backup (dotfile support)

### Settings Panel (KCM)
- **Live preview** — real-time preview with your actual desktop wallpaper as background, at 16:9 aspect ratio with proportional text scaling
- **Wallpaper preview** — the wallpaper image is rendered behind the preview text (C++ `QQuickImageProvider`), with a semi-transparent overlay for readability
- **Auto-scale simulation** — when auto-scale is enabled, text size adapts to fit within the preview area
- **Element reorder** — numbered list (① ② ③ ④ ⑤) with KDE-style arrows to reorder day, date, time, custom, and timezone
- **Organized UI** — sections for Preview, Global, Day, Date, Time, Custom Text, Timezone, and Themes

### Debug Page
- **System diagnostics** — displays Qt version, platform, screen resolution, locale
- **Plugin status** — shows whether TimeZone and Wallpaper C++ plugins are loaded
- **Theme color detection** — reports Plasma theme colors when available (shows "N/A" in standalone KCM context)
- **Wallpaper info** — current wallpaper path, detected brightness (dark/light), color scheme
- **Font browser** — lists up to 339 available system fonts
- **Log viewer** — full log history displayed inline, with copy button
- **Async log fetch** — fetch Plasma Shell logs via `journalctl` asynchronously (non-blocking)
- **Export to file** — save complete debug info to `/tmp/modernreclock_log_export.txt`

### Internationalization
- **13 language presets** — locale presets for date/time formatting: English, French, German, Spanish, Italian, Dutch, Polish, Portuguese, Russian, Japanese, and more
- **Translated UI** — currently translated in English, French, German, and Spanish
- **Contributing** — translations welcome! See the [Translations](#translations) section

## Installation

### From KDE Store (Recommended)

Install directly from the KDE Store in your Plasma desktop:
1. Right-click your desktop or panel → "Add Widgets"
2. Click "Get New Widgets..." → "Download New Plasma Widgets"
3. Search for "Modern reClock"
4. Click "Install"

### Quick install (Recommended)

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/YoannDev90/KDE-Modern-reClock/main/install-dist.sh)"
```

### From a release

1. Download `com.github.yoanndev90.modernreclock-VERSION.plasmoid` from the [latest release](https://github.com/YoannDev90/KDE-Modern-reClock/releases/latest)
2. Install:
   ```bash
   kpackagetool6 -t Plasma/Applet -i com.github.yoanndev90.modernreclock-VERSION.plasmoid
   ```
3. Or use Plasma installer ("Add Widgets" > "Install from Local File")

> **Note**: The universal `.plasmoid` works without the C++ plugin. For full features (timezone, wallpaper detection), use `install-dist.sh` or install the plugin manually.

> **C++ plugins**: The install script will try to build all C++ plugins (timezone, wallpaper, and logger) from source. If cmake/KF6-dev are not installed, it will automatically download precompiled binaries for your architecture from the release.

### Offline install (no internet required)

1. Download from the release:
   - `com.github.yoanndev90.modernreclock-VERSION.plasmoid`
   - `modernreclock-plugins-VERSION-ARCH.zip` (matching your architecture)
2. Extract the zip, run `install-local.sh` from the extracted folder

### From source (for developers)

```bash
git clone https://github.com/YoannDev90/KDE-Modern-reClock
cd KDE-Modern-reClock
./install-local.sh
```

Use `--fr` to restart Plasma automatically:
```bash
./install-local.sh --fr
```

## C++ Plugins

The widget ships three C++ Qt6/QML plugins compiled into a single shared library `libmodernreclock_backend.so`:

| Plugin | Namespace | Purpose |
|--------|-----------|---------|
| **TimeZoneHelper** | `ModernRecClock.TimeZone` | IANA timezone formatting via `QDateTime::toTimeZone()` |
| **WallpaperHelper** | `ModernRecClock.Wallpaper` | Desktop wallpaper path detection + brightness + `QFileSystemWatcher` |
| **WallpaperConfig** | Internal | Shared INI parsing for `plasma-org.kde.plasma.desktop-appletsrc` and `kdeglobals` |
| **WallpaperImageProvider** | `image://modernreclock/wallpaper` | QQuickImageProvider serving the current wallpaper for the KCM preview |
| **Logger** | `ModernRecClock.Log` | Structured logging (info/debug/warn), async journalctl fetch, file export |

## Supported Architectures

| Arch | Status |
|------|--------|
| x86_64 | ✅ Precompiled binary available |
| aarch64 | ✅ Precompiled binary available |

Other architectures: compile from source with `cmake` and `kf6-coreaddons-dev`.

## Debugging

Open the widget's configuration panel and navigate to the **Debug** tab. You can:

1. View system info, plugin status, and wallpaper diagnostics
2. Browse available system fonts
3. Review the full log history for all widget components
4. Copy debug info to clipboard for bug reports
5. Export logs to `/tmp/modernreclock_log_export.txt` for sharing
6. Fetch recent Plasma Shell logs asynchronously (requires `journalctl` access)

## Translations

If you want to help translate this widget:

1. Go to the `translate/` folder.
2. If your language doesn't have a `.po` file yet, use `template.pot` to create one (e.g., `fr.po`).
3. Use a tool like **Poedit** to fill in the translations.
4. Run the `merge.sh` script to update the template and sync your `.po` file with new strings:

   ```bash
   cd translate
   ./merge.sh
   ```

5. Run the `build.sh` script to compile the translations:

   ```bash
   ./build.sh
   ```

6. Submit a Pull Request with your new or updated `.po` file!

## Community Themes

<!-- COMMUNITY_THEMES_START -->

<p align="center">
<a href="https://raw.githubusercontent.com/YoannDev90/KDE-Modern-reClock/main/community_themes/themes/theme.zip"><img src="https://raw.githubusercontent.com/YoannDev90/KDE-Modern-reClock/main/community_themes/previews/theme.png" width="300" alt="Theme"></a>
</p>
<!-- COMMUNITY_THEMES_END -->

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
