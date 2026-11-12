# NeonOmen 1.0.4-alpha.4

Alpha build for the World of Warcraft Forever client.

- Fix the threat meter's window layer so normal system windows remain above it.
- Add a NeonCast-style settings console with five pages, theme presets, styled controls and fixed sample bars.
- Use full-width sidebar labels and a thin custom scrollbar without native gold arrows.
- Replace stretched rounded fills and vertical end-caps with satin threat bars, horizontal detail and straight ends.
- Preserve warning colors, class/custom colors and protected threat-value handling.
- Use the `NeonOmen/` installation folder with `NeonOmen.toc` and `NeonOmen.lua`.
- Retain `/orf`, saved-variable compatibility and binding command IDs; add `/neonomen`.

**Validation:** 30 automated checks passed. The installable ZIP contains 11
runtime files under one `NeonOmen/` directory. Automated tests use a simulated UI;
in-game rendering and combat behavior still need verification.

Install the versioned ZIP below, not GitHub's generated source archives. Existing
`NeonOmen` installations can update the addon folder and use `/reload`. Migration
from `OmenReloadedForever` is documented in the README.

中文：本次修复主面板遮挡系统窗口的问题，重做分页设置、左侧导航及滚动条，
将仇恨条改为直切末端与细横纹材质，移除拉伸圆角和末端竖线。
当前仍为测试版，请在永恒客户端验证显示与战斗交互。
