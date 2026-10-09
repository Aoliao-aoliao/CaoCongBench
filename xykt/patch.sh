#!/bin/bash
# 给 xykt 的测试脚本去广告，并校验结果。
# 用法：bash xykt/patch.sh <原始脚本> <输出脚本>
# 校验不通过时返回非 0，且不写输出文件。
#
# 修改内容（都在函数层面，xykt 调整调用位置也不会失效）：
#   1. show_ad   —— 运行开头的赞助广告：函数直接返回
#   2. show_tail —— 报告末尾的检测量统计和致谢：函数直接返回
#   3. upload.check.place —— 结果上传到 xykt 服务器、生成 Report.Check.Place 链接：整行注释掉
#   4. IP 报告的地图链接 —— 原来指向 check.place（实际会跳到他的脚本菜单），换成谷歌地图官方链接
#   5. 报告标题下的项目地址和运行命令（shead[git] / shead[bash]）—— 换成草丛测评的仓库地址和一键命令
#      地址和命令取自 CaoCong.sh 配置区，换域名只需改那一处
#      版权与致谢保留在本仓库的 README、LICENSE 和网站页脚（AGPL-3.0 要求）
set -u

src="$1"
out="$2"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

conf="$(dirname "$0")/../CaoCong.sh"
cc_repo="$(sed -n 's/^cc_repo="\([^"]*\)".*/\1/p' "$conf")"
cc_run="$(sed -n 's/^cc_run="\([^"]*\)".*/\1/p' "$conf")"
cc_git="https://github.com/$cc_repo"
cc_cmd="bash <(curl -sL $cc_run)"

sed -E \
    -e 's/^show_ad\(\)\{/show_ad(){ return 0;/' \
    -e 's/^show_tail\(\)\{/show_tail(){ return 0;/' \
    -e '/upload\.check\.place/s/^/: # /' \
    -e 's#https://check\.place/\$lat,\$lon,\$zoom_level,\$YY#https://www.google.com/maps?q=$lat,$lon\&z=$zoom_level#' \
    -e "s#^shead\[git\]=\".*\"\$#shead[git]=\"$cc_git\"#" \
    -e "s#^shead\[bash\]=\".*\"\$#shead[bash]=\"$cc_cmd\"#" \
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
check "没有 check.place 地图链接" '! grep -q "check\.place/\$lat" "$tmp"'
if grep -q '^generate_googlemap_url()' "$tmp"; then
    check "地图链接已换成谷歌地图（恰好 1 处）" '[[ $(grep -cF "https://www.google.com/maps?q=\$lat,\$lon&z=\$zoom_level" "$tmp") -eq 1 ]]'
fi
check "读到草丛测评的仓库和命令配置" '[[ -n $cc_repo && -n $cc_run ]]'
check "项目地址全部换成草丛测评" '[[ $(grep -c "^shead\[git\]=" "$tmp") -ge 1 && $(grep "^shead\[git\]=" "$tmp" | grep -vcF "shead[git]=\"$cc_git\"") -eq 0 ]]'
check "运行命令全部换成草丛测评" '[[ $(grep -c "^shead\[bash\]=" "$tmp") -ge 1 && $(grep "^shead\[bash\]=" "$tmp" | grep -vcF "shead[bash]=\"$cc_cmd\"") -eq 0 ]]'
check "bash 语法正确" 'bash -n "$tmp"'

if [[ $fail -ne 0 ]]; then
    echo "校验失败，不输出"
    exit 1
fi
cp "$tmp" "$out"
echo "已输出 $out"
