#!/bin/zsh

set -u

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h:h}"
GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
TOOL_SCRIPT="res://qa_tools/fishing_level_skipper/skip_to_next_new_fish.gd"
TOOL_LOG="/private/tmp/desktop-pet-qa-fishing-skipper.log"

echo "Fishing QA — 跳到下一个有新鱼出现的关卡"
echo ""
echo "请先完全关闭正在运行的 Desktop Pet，避免游戏退出时覆盖刚修改的存档。"
echo "下面先做只读预览："
echo ""

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "找不到 Godot：$GODOT_BIN"
  read "reply?按 Enter 关闭…"
  exit 1
fi

cd "$PROJECT_ROOT"
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --log-file "$TOOL_LOG" -s "$TOOL_SCRIPT" -- --preview
preview_status=$?
if [[ $preview_status -ne 0 ]]; then
  echo ""
  echo "预览失败，存档没有改变。"
  read "reply?按 Enter 关闭…"
  exit $preview_status
fi

echo ""
read "answer?确认按以上方案结算并跳关？输入 y 后按 Enter："
if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
  echo "已取消，存档没有改变。"
  read "reply?按 Enter 关闭…"
  exit 0
fi

"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --log-file "$TOOL_LOG" -s "$TOOL_SCRIPT" -- --apply
apply_status=$?
echo ""
if [[ $apply_status -eq 0 ]]; then
  echo "完成。现在可以重新打开游戏，直接玩下一条新鱼出现的关卡。"
else
  echo "执行失败；请查看上方错误。"
fi
read "reply?按 Enter 关闭…"
exit $apply_status
