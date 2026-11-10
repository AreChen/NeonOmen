# Development and verification

`Locale.lua`, `UI/Theme.lua` and the main file load in TOC order. Keep visual helpers
in the private addon namespace. The installation directory and TOC are `NeonOmen`
and `NeonOmen.toc`. Media paths must use this directory too. The historical
`OmenReloadedForeverDB` saved-variable key and keybinding IDs remain supported.
WoW now loads that table from `SavedVariables/NeonOmen.lua`; see the upgrade steps
in the README for migrating the old file.

`Options.lua` receives settings getters and actions from the core. It reads the
current DB on every interaction, including after SavedVariables replacement.
`UI/Widgets.lua` owns the styled switches and sliders; synchronization must never
write back to settings or trigger geometry changes. `UI/OptionsLocale.lua` provides
English fallback plus Simplified and Traditional Chinese console text.

The standalone settings frame uses DIALOG; the meter remains LOW. The native
settings category is a launcher, so the full console keeps its navigation and
preview layout. The sample uses the actual bar skin and color-selection function
without joining the threat scan or enabling the main meter's test mode.

## Automated checks

```sh
python -m venv .venv
.venv/bin/python -m pip install -r requirements-dev.txt
.venv/bin/python -m pytest tests -q
.venv/bin/python tools/package.py
```

Tests load the actual TOC with a simulated WoW UI in Lua 5.1. They cover saved-variable
loading, English and Chinese previews, legacy rendering APIs, layer inheritance,
zero and secret values, glow settings, warning colors and deferred settings access.
They cannot establish actual client rendering, taint behavior or combat compatibility.

## Forever client checklist

- With the game closed, copy the legacy settings file as documented. Install into `NeonOmen`, remove the old addon directory, and confirm position, size, visibility, colors and keybindings survive login and `/reload`.
- Use `/orf test`, then overlap the meter with the game menu, system settings, bags and dialogs. Click and drag the meter, and reopen those windows. The meter must stay below them.
- Open `/orf` in both the native settings host and the standalone fallback where available.
- Check normal, yellow, red and class colors. Toggle glow and verify the leading edge remains visible. At zero, no glow or bright marker should remain.
- Resize the meter, change row height and UI scale, and enable upward growth and auto-collapse. Check that the fill, shading, edge and text stay aligned.
- Enter a party/dungeon with protected threat values; confirm bars update without Lua errors or blocked actions. Return to ordinary values and confirm smoothing resumes.
- Enter combat, request settings, and leave combat; settings should open afterward.
- Open every console page, scroll its cards, and test switches, slider steps, presets, color-picker apply/cancel, class filters and every alert sound. The preview must update immediately while preserving warning colors.
- Open settings from the minimap, slash commands and native launcher. Test Escape, close/reopen, dragging, UI scaling and small screens in English and Chinese. Verify scrollbar behavior and the fixed preview stay usable.

Keep the version prerelease until these checks pass. No release tag is created by the packaging tool.
