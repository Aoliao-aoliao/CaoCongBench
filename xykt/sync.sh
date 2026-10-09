#!/bin/bash
# 从 xykt 下载最新的三个测试脚本，去广告、校验后存入 xykt/ 目录。
# 任意一个校验失败就整体不更新，保留上一次的干净版本。
set -u
cd "$(dirname "$0")"

declare -A sources=(
    [hq.sh]="https://Hardware.Check.Place"
    [iq.sh]="https://IP.Check.Place"
    [nq.sh]="https://Net.Check.Place"
)

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

for name in hq.sh iq.sh nq.sh; do
    url="${sources[$name]}"
    echo "== $name ← $url"
    curl -fsSL --retry 3 "$url" -o "$workdir/$name.orig" || { echo "下载失败"; exit 1; }
    bash patch.sh "$workdir/$name.orig" "$workdir/$name" || exit 1
    # 记录上游版本号，方便查看
    ver="$(grep -m1 -oE 'script_version="[^"]+"' "$workdir/$name.orig" | cut -d'"' -f2)"
    echo "$name ${ver:-unknown}" >> "$workdir/VERSIONS"
done

chmod 644 "$workdir"/hq.sh "$workdir"/iq.sh "$workdir"/nq.sh
mv "$workdir"/hq.sh "$workdir"/iq.sh "$workdir"/nq.sh .
sort "$workdir/VERSIONS" > VERSIONS
echo "== 完成"
cat VERSIONS
