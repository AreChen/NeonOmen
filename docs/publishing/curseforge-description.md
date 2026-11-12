# NeonOmen — Threat Meter & Aggro Alerts for WoW Forever

**NeonOmen is a standalone threat meter addon for World of Warcraft Forever.**
Monitor threat percentages, threat per second (TPS), party and raid aggro, and
pets in a customizable neon interface. English, Simplified Chinese and
Traditional Chinese settings are included.

## Features

- Threat percentages, optional raw threat values, and TPS over the last 10 seconds.
- Party, raid and pet support, class filters, focus-target priority and an option to keep your own bar visible.
- Configurable aggro warnings: threshold, sound, screen flash, text and optional screen shake.
- Warning colors retain priority over class and custom colors.
- Five accent presets, custom colors, glow and opacity controls.
- Satin bars with fine horizontal reflections and clean, straight fill ends.
- A five-page settings console with fixed sample bars for inspecting materials and colors.
- Width, height, spacing and scale controls, locking, click-through, upward growth and auto-collapse.
- A LOW-layer meter that stays below normal system windows.

## Client and version

Designed for the **World of Warcraft Forever client**. Current build:
**1.0.4-alpha.4**. This is an alpha build; rendering and combat behavior still
require in-game verification. Compatibility with other WoW client variants has
not been verified.

## Installation

Extract the `NeonOmen` folder to `Interface/AddOns`, then reload the UI.
The entry file should be `Interface/AddOns/NeonOmen/NeonOmen.toc`.
Open settings with `/neonomen` or `/orf`; use `/orf test` to toggle the main
meter's sample bars. Settings are also available through the minimap button.

Upgrading from the old `OmenReloadedForever` folder? Exit the game and back up
settings, then copy `SavedVariables/OmenReloadedForever.lua` to
`SavedVariables/NeonOmen.lua` under the same WoW account directory. Keep the
`OmenReloadedForeverDB` variable name inside the file. Remove the old addon
directory after installing the new one.

## 简体中文

NeonOmen 是面向魔兽世界永恒服的仇恨监测插件，可查看仇恨百分比、原始仇恨值和每秒仇恨（TPS），
并配置队伍、团队、宠物显示与仇恨警报。提供五套霓虹配色、细横纹仇恨条、分页设置和固定示例预览。

将 `NeonOmen` 文件夹放入 `Interface/AddOns`，输入 `/reload` 后使用 `/neonomen` 或 `/orf`
打开设置。当前为 `1.0.4-alpha.4` 测试版，目标客户端为 World of Warcraft Forever。

## Links and credits

- Source and documentation: https://github.com/AreChen/NeonOmen
- Simplified Chinese: https://github.com/AreChen/NeonOmen/blob/main/README.zh-CN.md
- Traditional Chinese: https://github.com/AreChen/NeonOmen/blob/main/README.zh-TW.md
- Bug reports: https://github.com/AreChen/NeonOmen/issues

The original OmenReloadedForever addon identifies Cryptotaxi as its author.
NeonOmen customization is maintained by AreChen. The neon card assets originated
in the local NeonCast project.
