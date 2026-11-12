# NeonOmen — WoW Forever Threat Meter & Aggro Alerts

**NeonOmen is a standalone threat meter addon for World of Warcraft Forever.**
Track threat percentages, threat per second (TPS), party and raid aggro, and pets
through a customizable neon interface with English, 简体中文 and 繁體中文 support.

[简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) ·
[Download builds](https://github.com/AreChen/NeonOmen/releases) ·
[Report an issue](https://github.com/AreChen/NeonOmen/issues)

## Threat tracking and warnings

- **Threat meter:** threat percentages, optional raw threat values, and TPS over the last 10 seconds.
- **Party, raid and pets:** class filters, focus-target priority, and an option to keep your own bar visible.
- **Aggro alerts:** configurable warning threshold, sound, screen flash, warning text and optional screen shake.
- **Readable risk colors:** warning colors retain priority when class colors or custom bar colors are enabled.
- **Flexible visibility:** configure solo, pet, party, raid, combat, resting-area and PvP display rules.

## Neon interface

- Five accent presets, custom colors, glow, background opacity and overall opacity.
- Satin threat bars with fine horizontal reflections and clean, straight fill ends.
- A five-page settings console for appearance, layout, data labels, visibility and alerts.
- Fixed sample bars for inspecting colors and materials without starting the main meter's test mode.
- Width, height, bar spacing, scale, upward growth, auto-collapse, locking and click-through controls.
- A LOW-layer meter that stays below normal system windows; a separate DIALOG-layer settings console.

![NeonOmen settings and threat-bar simulation; not an in-game screenshot](docs/settings-preview.zh-CN.png)

The preview above is a simulated layout. The current build is **1.0.4-alpha.4**;
client rendering and combat behavior still require in-game verification.
NeonOmen targets the **World of Warcraft Forever client**. Other WoW client
variants have not been verified.

## Install NeonOmen

1. Download the installable ZIP from [GitHub Releases](https://github.com/AreChen/NeonOmen/releases).
2. Extract the `NeonOmen` folder into your game's `Interface/AddOns` directory.
3. Confirm the entry file is `Interface/AddOns/NeonOmen/NeonOmen.toc`.
4. Reload the game UI with `/reload`, then open settings with `/neonomen` or `/orf`.

The installation ZIP contains one `NeonOmen/` folder with runtime files only.
Repository source archives include development files; use the versioned addon
ZIP attached to a release for installation. The `NeonOmen-test-build` Actions
artifact also extracts directly to the addon folder.

### Upgrading from OmenReloadedForever

Exit the game and back up your settings. Copy
`WTF/Account/<account>/SavedVariables/OmenReloadedForever.lua` to
`WTF/Account/<account>/SavedVariables/NeonOmen.lua`. Keep the
`OmenReloadedForeverDB` variable inside the file unchanged. Back up any existing
`NeonOmen.lua` settings file before replacing it.

Install the new `NeonOmen` addon folder and remove the old
`Interface/AddOns/OmenReloadedForever` folder. Existing binding command IDs and
`/orf` remain supported. See [the Chinese migration guide](docs/UPGRADING.zh-CN.md).

## Commands

| Command | Action |
| --- | --- |
| `/neonomen` or `/orf` | Open settings |
| `/orf test` | Toggle the main meter's sample/test bars |
| `/orf toggle` | Show or hide the meter |
| `/orf lock` / `/orf unlock` | Lock or unlock its position |
| `/orf reset` | Reset its position and window size |
| `/orf debug` | Print client and threat API diagnostics |

The minimap button also opens settings. A settings request made during combat
opens after combat ends.

## Feedback and development

For a bug report, include the addon version, client language, steps to reproduce,
Lua error text and, where useful, `/orf debug` output or a screenshot.
Use [GitHub Issues](https://github.com/AreChen/NeonOmen/issues).

Development setup, packaging and the client verification checklist are in
[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md). See [CHANGELOG.md](CHANGELOG.md) for changes.
Tests and simulated previews do not establish in-game compatibility.

## Attribution and license

The original OmenReloadedForever addon identifies **Cryptotaxi** as its author.
This repository contains the NeonOmen customization maintained by **AreChen**.
The neon card assets originated in the local NeonCast project.
No license was included in the original installed copy, and this repository has
not declared a license; redistribution rights have not been established here.
