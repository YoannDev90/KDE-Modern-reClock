<p align="center">
  <img src="https://github.com/YoannDev90/KDE-Modern-reClock/blob/main/assets/logo.jpg" width=100/>
  <h2 align="center">Modern reClock for KDE</h2>
  <p align="center">A modern looking clock widget !</center>
</p>

<p align="center">
<a href="https://github.com/YoannDev90/KDE-Modern-reClock/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/YoannDev90/KDE-Modern-reClock?color=%233DAEE9&style=for-the-badge"></a>
<a href="https://github.com/YoannDev90/KDE-Modern-reClock/network"><img alt="GitHub forks" src="https://img.shields.io/github/forks/YoannDev90/KDE-Modern-reClock?color=%233DAEE9&style=for-the-badge"></a>
<a href="https://github.com/YoannDev90/KDE-Modern-reClock/issues"><img alt="GitHub issues" src="https://img.shields.io/github/issues/YoannDev90/KDE-Modern-reClock?color=%233DAEE9&style=for-the-badge"></a>
</p>

<p align="center">
  <img src="https://github.com/YoannDev90/KDE-Modern-reClock/blob/main/assets/screenshot.png"/>
</p>

## Improvements

- Added auto-scale feature (widget content fits its size)
- Improved rendering with SDF (Signed Distance Field) for maximum sharpness at any scale
- Added support for seconds
- Added support for custom time format
- Added configurable spacing between elements
- Fixed letter spacing minimum to allow 0
- Added tooltips and placeholder text for date/time format fields
- Consistent widget name across codebase
- Added custom day format (e.g. full name vs abbreviated)
- Added uppercase toggle for day and date rows
- Added bold font toggle for day, date, and time sections
- Added support for custom locale
- Added language presets for quick configuration
- Added organized settings UI (Global, Day, Date, Time)
- Added JSON Import/Export for easy configuration backup (Dotfile support)
- Added immediate preview for translation and format changes
- Migrated translation structure to Plasma 6 standards
- Flattened repository structure for better developer experience

## Installation

#### KDE Store

1. Right click on the desktop
2. Click on "Add Widgets"
3. Click on "Get New Widgets"
4. Click on "Download New Plasma Widgets"
5. Search for "Modern reClock"
6. Click on "Install" and you're done!

#### From this repository (Manual)

1. Clone this repository  
   `git clone https://github.com/YoannDev90/KDE-Modern-reClock && cd KDE-Modern-reClock/`
2. Install using the script  
   `./install-local.sh`

   *Use the `--fr` or `-force-reload` flag to automatically restart Plasma and see changes immediately:*  
   `./install-local.sh --fr`

#### One-line installation (Recommended for quick testing)

Run the following command in your terminal:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/YoannDev90/KDE-Modern-reClock/main/install-dist.sh)"
```

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

5. Run the `build.sh` script to compile the translations and install them into the widget:

   ```bash
   ./build.sh
   ```

6. Submit a Pull Request with your new or updated `.po` file!

## Community Screenshots

<details>
<summary>Click to view setups from the community</summary>


<!-- COMMUNITY_SCREENSHOTS_START -->
|Screenshots|
|---|
| ![YoannDev90](https://github.com/YoannDev90/KDE-Modern-reClock/blob/main/assets/community/screenshot_5.png?raw=true) |
| ![YoannDev90](https://github.com/YoannDev90/KDE-Modern-reClock/blob/main/assets/community/screenshot_6.png?raw=true) |
<!-- COMMUNITY_SCREENSHOTS_END -->

</details>
