# 浏览器 AI 发布交接

目标：在当前用户的 CurseForge 账号中创建或更新 **NeonOmen**，上传 `1.0.4-alpha.4`。
先检查是否已有同名项目，避免重复创建。用户已授权项目创建、资料填写和版本上传。

## 填写资料

- 项目名称：`NeonOmen`；建议 slug：`neonomen`。
- 游戏：World of Warcraft；目标客户端：**World of Warcraft Forever**，TOC Interface 为 `16001`。
- 简介及其他字段：[curseforge-project.json](curseforge-project.json)。
- 项目详细说明：完整使用 [curseforge-description.md](curseforge-description.md)。
- 本次更新日志：[release-notes-1.0.4-alpha.4.md](release-notes-1.0.4-alpha.4.md)。
- 源码：https://github.com/AreChen/NeonOmen 。问题反馈：https://github.com/AreChen/NeonOmen/issues 。
- 建议主分类：Combat；以 CurseForge 实际提供的分类为准。
- 类型必须选择 **Alpha**，不要标记为稳定 Release。

## 上传文件

从 https://github.com/AreChen/NeonOmen/releases/tag/v1.0.4-alpha.4 下载
`NeonOmen-1.0.4-alpha.4.zip` 和同页的校验文件。核对 SHA-256 后上传插件 ZIP。
不要上传 GitHub 自动生成的 Source code 压缩包、校验文件或整个开发仓库。
安装包应仅包含一层 `NeonOmen/` 和 11 个运行文件。

兼容版本必须与实际 Forever 客户端及项目支持列表对应；若平台没有可匹配选项，先报告用户，
不要为了通过表单随意选择正式服、经典服或最新版本。

仓库尚未声明许可证。保留 Cryptotaxi 的原始署名和 AreChen 的维护署名；
若创建项目必须选择许可证，向用户确认，勿自行填写 MIT、GPL 或独占授权声明。

仓库截图标明为模拟预览，使用时应保留这一说明，不能称为游戏实测截图。
提交后核对项目名、Alpha 类型、文件版本、下载文件名、兼容版本及处理状态。
最后向用户提供项目页、文件页和审核/可下载状态；若待审核，不要报告为已公开上线。

## 同时补齐 GitHub About（当前连接返回 403）

当前 API 授权可以更新代码，但修改 GitHub 仓库简介及 Topics 被拒绝。
如果浏览器已有该仓库的管理权限，请在仓库首页 About 设置中应用
[.github/repository-metadata.json](../../.github/repository-metadata.json) 的简介和 Topics。
保留用户已经添加的相关 Topics。设置完成后重新打开仓库首页确认保存成功。

CurseForge 项目公开后，把其实际项目 URL 回填到 GitHub About 的 Website 字段，
并在 README 下载入口增加真实链接。不要使用尚未创建的猜测项目 URL。
