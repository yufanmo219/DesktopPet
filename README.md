# Desktop Pet

一款以陪伴、休闲和可爱为核心的 2D PC 虚拟养宠物游戏原型，使用 Godot 4.7 制作。

## 当前已经实现

- 启动游戏后直接进入 Home，默认伙伴为橘猫 Maple
- Home 的 **Adopt another cat** 会进入独立的 `StoreScreen` 商店组件
- 商店使用翻开的旧书界面：左页九宫格、右页猫咪详情、当前 XP 和返回 Home
- Maple 默认已拥有；其余八只猫暂用锁定占位头像，点击后显示蒙版、锁头和动态 XP 按钮文字
- 点击锁定猫咪的 **Unlock with XX XP** 会先显示动态猫名/价格确认框；选择 **Yes** 后显示带钓鱼成功彩带、猫咪和名字的 Congratulations UI（当前仅做 UI，不扣 XP 或解锁）
- 商店名称、简介、XP 和按钮文字全部由 Godot 控件显示，可以继续更换字体和内容
- 全部游戏文字统一为大写，并使用玩家原创手写字体：无阴影白字、珊瑚色阴影字、白色阴影按钮字
- Home 显示共享 XP；猫咪进入 Home 时睡觉，鼠标移动到左侧宠物区域后醒来
- Home 的 **My Aquarium** 按钮进入独立鱼缸页面
- My Aquarium 使用纯背景、实时文字和独立鱼图层；绿鱼会在水域内随机游动、自动转向，也会随机停下几秒
- 钓鱼：独立的 `FishingGame` 组件；3 种鱼分别奖励 4、6、10 XP，包含六帧举网、成功/失败结果页
- Desktop Companion：所有猫共用紧凑的三按钮控制框，顶部替换为各自的专属场景；Maple 当前使用侧视花草坪
- 控制框只保留横排的 **Go Home / Follow Me / Quit** 三个圆角按钮；Station 初始位于当前屏幕右下角，按钮以外的整个 Station 都可拖动到任意显示器
- 猫咪被拖走 15 秒后自动回到 Station；鼠标 30 秒未进入 Station 上方区域时睡觉，移到猫咪身上后醒来
- 橘猫在 Home 和 Desktop 中都固定落在阴影上，所有站立、跟随与睡觉的上下漂浮位移已删除
- Desktop 猫咪使用 Station 的独立原生子窗口；初次显示、Station 移动、猫咪拖动、Follow 和自动回站时都会重新提升猫咪层级，猫咪到站后也始终显示在 Station 前面
- Desktop 猫咪和 Station 共用 `90%` 缩放，内部 UI、阴影和停靠间距按同一比例缩小
- Desktop Station 使用四舍五入后的物理尺寸并填满透明窗口，避免 Retina 下 `90%` 缩放产生左右各 1px 的黑色留白
- Station 的 **Follow me / Unfollow** 可以开启或结束持续跟随鼠标；点击 **Unfollow** 后猫咪立即自己走回 Station，回站与追随鼠标共用 150 逻辑像素/秒的固定速度，不因距离远而加速
- Follow Me 开启时直接读取当前鼠标位置；每次从静止起步只等待 0.3–0.6 秒，追随中鼠标移动只更新目标，不会重置等待或让猫停下。距跟随落点 60 逻辑像素内停止，超过 100 逻辑像素再起步；保持原有移动速度与鼠标偏移，并随屏幕缩放适配距离
- 本地 JSON 自动存档，不需要联网或数据库
- 当前未完成的猫咪仍使用橘猫占位素材；Maple 已经具备坐姿、卧睡姿势，以及左右各 6 帧走路动画

## 打开和试玩

1. 打开 Godot。
2. 点击 **Import**。
3. 选择本文件夹中的 `project.godot`。
4. 导入后点击右上角的运行按钮，或按 `F6/F5`。

项目入口是 `main.tscn`，新旧存档都会直接进入 Home。

如果 Godot 使用嵌入式 Game 画面，点击 **Keep as desktop companion** 时，游戏会自动另开一个真正独立的透明挂件进程，并结束编辑器中正在运行的画面。也可以在 Godot 顶部 **Game** 页右上角的菜单中关闭 **Embed Game on Next Play**，让所有试玩都直接使用独立窗口。

桌面模式使用两个可见的透明原生窗口：Station 保持在自己的位置，猫咪可以独立拖到桌面其他位置，因此不会用一个全屏透明层挡住其他应用。

## 存档

存档文件名为 `desktop_pet_save.json`，由 Godot 写入本机的 `user://` 目录。它保存当前宠物、共享 XP、钓鱼进度、鱼缸、爱心，以及商店中的 `owned_cat_ids`。旧存档的共享进度字段会在加载时自动迁移成 `progress_stats`，不会重算关卡、XP、爱心或鱼图鉴。当前版本不会把玩家数据上传到服务器。

## 原创字体

手写原稿保存在 `dev_only/unused_assets/assets/font_source/original_handwriting_filled.png`，最终游戏使用的矢量字体是 `assets/fonts/original_handwriting/yufan_original_handwriting.ttf`。Godot 会在任意字号下实时抗锯齿渲染，颜色、描边和阴影由界面样式生成，不再缩放固定分辨率的字形图集。字体来自玩家原创手写内容，不依赖第三方商业字体许可。

需要重新生成字体时运行：

```bash
python3 tools/build_original_handwriting_ttf.py
```

## 资源目录

`assets/` 只保留当前运行时会直接或动态加载的资源。未接入游戏的源图、旧版图、预览图和动画母版保存在 `dev_only/unused_assets/`，并维持原来的相对路径。`dev_only/.gdignore` 让 Godot 跳过整个目录，因此这些文件不会被导入或跟随游戏导出。完整移动清单在 `dev_only/unused_assets_manifest.txt`；可运行 `python3 dev_only/audit_unused_assets.py` 重新审计，必要时用 `--restore` 恢复归档。

## 自动验证

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /private/tmp/desktop-pet-smoke.log -s res://tests/smoke_test.gd -- --test-mode
```
