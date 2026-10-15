# Desktop Pet

[English](../README.md) | 简体中文

Desktop Pet 是一款使用 Godot 4.7 制作的 2D PC 虚拟养宠物游戏。它将原生桌面伙伴与轻量休闲玩法结合在一起，包括领养猫咪、钓鱼、鱼类图鉴和水族馆。

> **项目状态：** 正在进行发布前开发。目前仓库用于作品展示和技术评估，尚未发布经过正式签名的公开安装包。

## 主要功能

- 九只猫咪使用统一的宠物目录，并按需加载资源。
- 透明桌面伙伴支持独立的 Station 与宠物窗口、多显示器、拖动、跟随、睡眠和自动回站。
- 钓鱼系统包含等级、目标、鱼类稀有度、重试补偿、XP、爱心恢复和新鱼发现。
- Fishipedia 与 Aquarium 共用持久化的玩家进度。
- 本地 JSON 存档支持原子写入、备份恢复、旧版本迁移和未来版本保护。
- Windows 与 macOS 使用相同测试入口和可重复的 QA 导出流程。

## 游戏流程

游戏从 Home 页面启动，默认伙伴为 Maple。玩家可以进入 Cat Shelter 领养和选择伙伴，通过 Fishing 获得 XP、发现鱼类，在 Fishipedia 中查看收藏，并选择要放入 Aquarium 的鱼。当前伙伴也可以离开主游戏窗口，在桌面上陪伴玩家。

玩家数据只会写入 Godot 的本地 `user://` 目录，不需要账户、服务器或数据库。

## 从源码运行

需要安装：

- Godot 4.7.1
- Git LFS
- Python 3（用于测试和导出工具）

```bash
git lfs install
git clone https://github.com/yufanmo219/DesktopPet.git
cd DesktopPet
git lfs pull
```

在 Godot 中导入 `project.godot`，然后运行 `main.tscn`，或在编辑器中按 `F6`/`F5`。

如果 Godot 使用嵌入式游戏窗口，点击 **Keep as desktop companion** 会启动一个独立透明进程。也可以在 Godot 的 **Game** 菜单中关闭 **Embed Game on Next Play**。

## 自动验证

运行全部测试：

```bash
python3 tools/run_tests.py
```

运行特定测试：

```bash
python3 tools/run_tests.py --test save_game_repository
python3 tools/run_tests.py --test fishing_session
python3 tools/run_tests.py --test desktop_companion_state_machine
```

测试入口会先统一导入 Godot 资源，再隔离执行每个测试。GitHub Actions 会在 Windows 和 macOS 上运行同一套测试，同时验证 Git LFS 对象和普通 Git blob 大小。

## Windows / macOS QA 导出

安装 Godot 4.7.1 export templates 后运行：

```bash
python3 tools/export_builds.py --target windows
python3 tools/export_builds.py --target macos
```

生成结果保存在被忽略的 `build/` 目录。GitHub 的 **QA builds** workflow 会产生用于测试的未签名或 ad-hoc artifacts，但它们不属于正式发布版本。正式签名与 notarization 要求见 [发布流程](release.md)。

## 架构与贡献

- [架构说明（英文）](architecture.md)
- [发布流程（英文）](release.md)
- [贡献指南（英文）](../CONTRIBUTING.md)
- [安全报告方式（英文）](../SECURITY.md)

## 版权

Copyright © 2026 Yufan Mo。保留所有权利。

本仓库公开用于浏览、作品展示与技术评估。公开访问不代表授权复制、再发布、出售或复用代码、美术、动画、音频或字体。完整说明见 [LICENSE](../LICENSE)。
