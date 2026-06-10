<p align="center">
  <img src="https://github.com/YoannDev90/KDE-Modern-reClock/blob/main/assets/logo.jpg" width=100/>
  <h2 align="center">Modern reClock for KDE</h2>
  <p align="center">A modern looking clock widget for KDE Plasma 6!</p>
</p>

<p align="center">
<a href="https://github.com/YoannDev90/KDE-Modern-reClock/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/YoannDev90/KDE-Modern-reClock?color=%233DAEE9&style=for-the-badge"></a>
<a href="https://github.com/YoannDev90/KDE-Modern-reClock/network"><img alt="GitHub forks" src="https://img.shields.io/github/forks/YoannDev90/KDE-Modern-reClock?color=%233DAEE9&style=for-the-badge"></a>
<a href="https://github.com/YoannDev90/KDE-Modern-reClock/issues"><img alt="GitHub issues" src="https://img.shields.io/github/issues/YoannDev90/KDE-Modern-reClock?color=%233DAEE9&style=for-the-badge"></a>
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

### Custom Text Element
- **Static text** — display any custom message (e.g. "Good Morning", "Today is")
- **Dynamic format** — interpret text as Qt date/time format for live updates (e.g. `HH:mm`, `dddd d MMMM`)
- **Full styling** — separate font, size, spacing, bold, and color settings

### Secondary Timezone
- **Display any IANA timezone** — `America/New_York`, `Asia/Tokyo`, `Europe/Paris`, etc.
- **Timezone selector** — preset list of 40+ major cities, or type a custom IANA ID
- **Label support** — add a short label before the timezone (e.g. "NYC", "Tokyo")
- **Custom format** — control how the timezone time is displayed (`HH:mm`, `H:mm`, etc.)
- **DST-aware** — automatically handles daylight saving time via C++ Qt backend

### Day/Night Mode Adaptation
- **Auto color adaptation** — override all element colors with the system theme text color
- **Better contrast** — automatically adapts to light/dark desktop backgrounds

### Theming
- **Save/load themes** — save your configuration as named themes
- **Export/import** — share themes as JSON files
- **Per-section reset** — restore individual sections to defaults
- **JSON import/export** — full configuration backup (dotfile support)

### Settings Panel
- **Live preview** — see changes immediately in the config panel
- **Element reorder** — drag to reorder day, date, time, custom, and timezone
- **Organized UI** — sections for Global, Day, Date, Time, Custom Text, Timezone, and Themes

### Internationalization
- **13 languages** — English, French, German, Spanish, Italian, Dutch, Polish, Portuguese, Russian, Japanese, and more
- **Contributing** — translations welcome! See the [Translations](#translations) section

## Installation

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

> **Timezone plugin**: The install script will try to build the C++ timezone plugin from source. If cmake/KF6-dev are not installed, it will automatically download the precompiled binary for your architecture from the release.

### Offline install (no internet required)

1. Download from the release:
   - `com.github.yoanndev90.modernreclock-VERSION.plasmoid`
   - `modernreclock-timezone-VERSION-ARCH.zip` (matching your architecture)
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

## Supported Architectures

| Arch | Status |
|------|--------|
| x86_64 | ✅ Precompiled binary available |
| aarch64 | ✅ Precompiled binary available |

Other architectures: compile from source with `cmake` and `kf6-coreaddons-dev`.

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

## Community Screenshots

<details>
<summary>Click to view setups from the community</summary>

|Screenshots|
|---|

</details>

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
