# Changelog

## 1.0.4-alpha.4 — 2026-11-10

- Replace the narrow numbered sidebar buttons with full-width text tabs, soft selected backgrounds and horizontal underlines; avoid clipped numbers with custom client fonts.
- Replace client-template scrollbars with a thin styled thumb supporting wheel scrolling, dragging, clamped ranges and per-page scroll positions, without native gold arrows.
- Remove the stretched rounded threat mask, cylindrical bar texture and vertical progress cap. Use native rectangular fills with directional shading, fine horizontal brushing and a restrained top reflection.
- Keep all material layers within the native fill and hide them at zero, including while optional glow is disabled. Preserve warning colors and secret-value handling.
- Remove the meter's decorative title stripe and exclude the obsolete threat bitmaps from installation packages.
- Add regression coverage for short/wide rows, different heights, complete navigation labels and scroll limits. The client screenshots motivated this change; the new rendering still needs game verification.

## 1.0.4-alpha.3 — 2026-11-10

- Rebuild settings in NeonCast's visual style: numbered sidebar navigation, dark cards, accent wash, neon switches and numeric sliders with step buttons.
- Organize all existing controls into appearance, window layout, data labels, visibility and threat alerts, each with an independent scroll area.
- Add five matching accent presets and a fixed preview using the actual bar skin and threat-color rules. The sample does not enable the main meter's test mode.
- Open the standalone console directly from slash commands and the minimap; retain a native system-settings launcher and deferred opening after combat.
- Add width, window-height and spacing controls; preserve position reset, class filters, sound selection and custom colors with cancellation.
- Add English/Chinese console text and interaction checks for navigation, geometry, themes, samples and the native launcher. In-game rendering still requires verification.

## 1.0.4-alpha.2 — 2026-11-10

- Use `NeonOmen/` for the installation package, with `NeonOmen.toc`, `NeonOmen.lua` and matching media paths.
- Display NeonOmen in the system settings category and support `/neonomen` alongside `/orf`.
- Retain the existing saved-variable key and binding command IDs; document the one-time settings-file copy required when upgrading from the old addon folder.
- Upload an Actions artifact that extracts directly to `NeonOmen/`, without a nested installation ZIP.
- Test the new TOC name, packaged media paths and loading of copied legacy settings.

## 1.0.4-alpha.1 — 2026-11-10

- Place the threat meter and its child bars in the LOW stratum, below system windows; disable automatic top-level raising.
- Match NeonCast's dark blue surfaces and muted headers, with a quieter frame outline and glow.
- Add a shaded threat-bar surface and a thin leading edge, with optional localized glow.
- Keep decorations attached to the native fill during resizing and animation; avoid arithmetic on secret threat values.
- Hide fill decorations at zero and preserve warning colors, class colors and existing saved settings.
- Add Lua 5.1 UI regression checks and a runtime-only installation package.

This alpha has simulated UI coverage. In-game visual, layering and combat checks are still required.
