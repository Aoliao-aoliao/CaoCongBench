#!/bin/bash
# 给 xykt 的测试脚本去广告，并校验结果。
# 用法：bash xykt/patch.sh <原始脚本> <输出脚本>
# 校验不通过时返回非 0，且不写输出文件。
#
# 修改内容（都在函数层面，xykt 调整调用位置也不会失效）：
#   1. show_ad   —— 运行开头的赞助广告：函数直接返回
#   2. show_tail —— 报告末尾的检测量统计和致谢：函数直接返回
#   3. upload.check.place —— 结果上传到 xykt 服务器、生成 Report.Check.Place 链接：整行注释掉
set -u

src="$1"
out="$2"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

sed -E \
    -e 's/^show_ad\(\)\{/show_ad(){ return 0;/' \
    -e 's/^show_tail\(\)\{/show_tail(){ return 0;/' \
    -e '/upload\.check\.place/s/^/: # /' \
    "$src" > "$tmp"

fail=0
check() {
    if eval "$2"; then
        echo "  ✔ $1"
    else
        echo "  ✘ $1"
        fail=1
    fi
}

echo "校验 $(basename "$src")："
check "show_ad 已失效（恰好 1 处）" '[[ $(grep -c "^show_ad(){ return 0;" "$tmp") -eq 1 ]]'
check "show_tail 已失效（恰好 1 处）" '[[ $(grep -c "^show_tail(){ return 0;" "$tmp") -eq 1 ]]'
check "没有生效中的 upload.check.place" '! grep -v "^: # " "$tmp" | grep -q "upload\.check\.place"'
# 广告文件只允许出现在 show_ad 函数体内（函数已失效，不会执行）
check "广告文件只在 show_ad 内引用" \
    '[[ -z $(awk "/^show_ad\\(\\)\\{/{f=1} f&&/^}/{f=0;next} !f && /sponsor\\.ans|ref\\/ad/" "$tmp") ]]'
check "bash 语法正确" 'bash -n "$tmp"'

if [[ $fail -ne 0 ]]; then
    echo "校验失败，不输出"
    exit 1
fi
cp "$tmp" "$out"
echo "已输出 $out"
