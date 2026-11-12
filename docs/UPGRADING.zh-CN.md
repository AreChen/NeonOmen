# 升级到 NeonOmen 目录

新版安装包解压后直接得到 `NeonOmen/`，安装到
`Interface/AddOns/NeonOmen`；其中应包含 `NeonOmen.toc`。

如果以前使用 `OmenReloadedForever` 目录，并且希望保留设置：

1. 完全退出游戏，备份原来的配置文件。
2. 将 `WTF/Account/<账号>/SavedVariables/OmenReloadedForever.lua` 复制一份，
   命名为同目录下的 `NeonOmen.lua`。文件里的 `OmenReloadedForeverDB` 不需要改名。
   如果已经有 `NeonOmen.lua`，先备份它，再决定是否用旧设置覆盖。
3. 安装新的 `Interface/AddOns/NeonOmen`，移除旧的
   `Interface/AddOns/OmenReloadedForever` 插件目录。
4. 进入游戏，使用 `/neonomen` 或 `/orf` 打开设置，使用 `/orf test` 预览。

插件无法在游戏内自动重命名磁盘上的配置文件。不复制旧配置时，新目录会使用默认设置，
原配置文件仍会保留。原有快捷键命令和 `/orf` 继续兼容。
