#!/bin/bash
#
# 草丛测评 CaoCong Bench —— 服务器一键测评脚本
# 作者：草丛
#
# 本脚本基于 NodeQuality（https://github.com/LloydAsp/NodeQuality，AGPL-3.0）修改，
# 测试核心来自 xykt 的 HardwareQuality / IPQuality / NetQuality（https://github.com/xykt）。
# 依照 AGPL-3.0，本脚本同样以 AGPL-3.0 开源。

############ 配置区：上线前只需要改这里 ############
cc_version="v1.0.0"
cc_site="https://caocong.example.com"          # 网站（报告页）
cc_run="https://run.caocong.example.com"       # 一键命令地址
cc_api="https://api.caocong.example.com"       # 上传接口
cc_repo="Aoliao-aoliao/CaoCongBench"           # GitHub 仓库（放脚本和 BenchOS）
cc_branch="main"
#####################################################

current_time="$(date +%Y_%m_%d_%H_%M_%S)"
work_dir=".caocong$current_time"
raw_file_prefix="https://raw.githubusercontent.com/$cc_repo/refs/heads/$cc_branch"

# BenchOS 下载源，按顺序尝试，前一个失败自动换下一个
arch_suffix=""
nexttrace_arch="amd64"
if uname -m | grep -Eq 'arm|aarch64'; then
    arch_suffix="-arm"
    nexttrace_arch="arm64"
fi
bench_os_urls=(
    "https://github.com/$cc_repo/releases/download/benchos-v1/BenchOs$arch_suffix.tar.gz"
    "https://github.com/LloydAsp/NodeQuality/releases/download/v0.0.2/BenchOs$arch_suffix.tar.gz"
)

header_info_filename=header_info.log
ip_quality_filename=ip_quality.log
ip_quality_json_filename=ip_quality.json
hardware_quality_filename=hardware_quality.log
hardware_quality_json_filename=hardware_quality.json
net_quality_filename=net_quality.log
net_quality_json_filename=net_quality.json
backroute_trace_filename=backroute_trace.log
backroute_trace_json_filename=backroute_trace.json

lang="cn"
opt_ipv=""
opt_lang=""

declare -A LANG
# ===== English =====
LANG[en.err01]="Error: work_dir does not contain 'caocong'!"
LANG[en.err02]="Error: Unsupported parameters!"
LANG[en.err03]="Error: the specified work_dir does not exist or is not readable/writable!"
LANG[en.err_root]="Error: please run this script as root."
LANG[en.err_cmd]="Error: missing required command:"
LANG[en.err_space]="Error: at least 2 GB of free disk space is required in"
LANG[en.err_download]="Error: failed to download BenchOS from all mirrors."
LANG[en.try_mirror]="Downloading BenchOS from"
LANG[en.err_fetch]="Error: failed to download test script:"
LANG[en.cleanup]="Cleaning, please wait a moment."
LANG[en.clean_fail]="An unexpected situation occurred: the BenchOS directory mount was not cleaned up properly. For safety, please reboot and then delete this directory."
LANG[en.ask_hq]="Run HardwareQuality test? (Enter for default 'y', 'f' for fast mode, 'v' for all test details) [y/f/v/n]: "
LANG[en.ask_iq]="Run IPQuality test? (Enter for default 'y') [y/n]: "
LANG[en.ask_nq]="Run NetQuality test? (Enter for default 'y', 'l' for low-data mode) [y/l/n]: "
LANG[en.ask_bt]="Run Backroute Trace test? (Enter for default 'y') [y/n]: "
LANG[en.cleanup_before]="Clean Up before Installation"
LANG[en.loadbench]="Load BenchOS"
LANG[en.basicinfo]="Hardware Info"
LANG[en.run_hq]="Running Hardware Quality Test..."
LANG[en.run_iq]="Running IP Quality Test..."
LANG[en.run_nq]="Running Network Quality Test..."
LANG[en.run_bt]="Running Backroute Trace..."
LANG[en.uploading]="Uploading results..."
LANG[en.upload_fail]="Upload failed. Results are not saved online."
LANG[en.cleanup_after]="Clean Up after Installation"
LANG[en.thanks]="Thanks for using CaoCong Bench!   Author: CaoCong"
LANG[en.thanks_sub]="More benchmark reports at"
# ===== Chinese =====
LANG[cn.err01]="错误：work_dir 不包含 'caocong'！"
LANG[cn.err02]="错误：不支持的参数！"
LANG[cn.err03]="错误：指定的 work_dir 不存在，或不可读/不可写！"
LANG[cn.err_root]="错误：请使用 root 用户运行本脚本。"
LANG[cn.err_cmd]="错误：缺少必需的命令："
LANG[cn.err_space]="错误：测试目录所在磁盘至少需要 2 GB 可用空间："
LANG[cn.err_download]="错误：所有下载源都无法下载 BenchOS。"
LANG[cn.try_mirror]="正在下载 BenchOS："
LANG[cn.err_fetch]="错误：测试脚本下载失败："
LANG[cn.cleanup]="清理中，请稍候。"
LANG[cn.clean_fail]="出现了预料之外的情况，BenchOS 目录的挂载未被清理干净，保险起见请重启后删除该目录。"
LANG[cn.ask_hq]="运行 硬件质量 测试？（回车默认 'y'，'f' 为快速模式，'v' 为深度模式）[y/f/v/n]："
LANG[cn.ask_iq]="运行 IP 质量 测试？（回车默认 'y'）[y/n]："
LANG[cn.ask_nq]="运行 网络质量 测试？（回车默认 'y'，'l' 为低流量模式）[y/l/n]："
LANG[cn.ask_bt]="运行 回程路由 测试？（回车默认 'y'）[y/n]："
LANG[cn.cleanup_before]="安装前清理"
LANG[cn.loadbench]="加载 BenchOS"
LANG[cn.basicinfo]="硬件信息"
LANG[cn.run_hq]="正在运行硬件质量测试..."
LANG[cn.run_iq]="正在运行 IP 质量测试..."
LANG[cn.run_nq]="正在运行网络质量测试..."
LANG[cn.run_bt]="正在运行回程路由追踪..."
LANG[cn.uploading]="正在上传测评结果..."
LANG[cn.upload_fail]="上传失败，本次结果未保存到网站。"
LANG[cn.cleanup_after]="安装后清理"
LANG[cn.thanks]="感谢使用草丛系列脚本！   作者：草丛"
LANG[cn.thanks_sub]="更多测评报告请访问"

function L(){
    local key="${lang}.${1}"
    echo "${LANG[$key]:-${LANG[en.$1]}}"
}

function start_ascii() {
    echo -e "\e[1;32m"
    cat <<'EOF'

 ██████╗  █████╗   ██████╗   ██████╗  ██████╗  ███╗   ██╗  ██████╗
██╔════╝ ██╔══██╗ ██╔═══██╗ ██╔════╝ ██╔═══██╗ ████╗  ██║ ██╔════╝
██║      ███████║ ██║   ██║ ██║      ██║   ██║ ██╔██╗ ██║ ██║  ███╗
██║      ██╔══██║ ██║   ██║ ██║      ██║   ██║ ██║╚██╗██║ ██║   ██║
╚██████╗ ██║  ██║ ╚██████╔╝ ╚██████╗ ╚██████╔╝ ██║ ╚████║ ╚██████╔╝
 ╚═════╝ ╚═╝  ╚═╝  ╚═════╝   ╚═════╝  ╚═════╝  ╚═╝  ╚═══╝  ╚═════╝

EOF
    if [[ "$lang" == "en" ]]; then
        cat <<EOF
CaoCong Bench $cc_version - server benchmark: hardware, IP quality and network quality

The benchmark runs inside a temporary system, and all traces are deleted afterwards.
It has no impact on the original environment and supports almost all Linux systems.

Author:  CaoCong
Command: bash <(curl -sL $cc_run)
EOF
    else
        cat <<EOF
草丛测评 $cc_version —— 服务器一键测评：硬件质量、IP 质量、网络质量

测试在临时系统中执行，结束后自动删除所有痕迹
不会对原系统产生任何影响，支持几乎所有 Linux 系统

作者：草丛
命令：bash <(curl -sL $cc_run)
EOF
    fi
    echo -e "\033[0m"
}

# 终端广告位：读取仓库里的 promo/terminal.txt，文件为空或下载失败就不显示
function show_promo(){
    local promo
    promo="$(curl -fsSL --max-time 5 "$raw_file_prefix/promo/terminal.txt" 2>/dev/null)"
    [[ -n "${promo//[[:space:]]/}" ]] && echo -e "$promo\n"
}

function _red() {
    echo -e "\033[0;31m$1\033[0m"
}

function _yellow() {
    echo -e "\033[0;33m$1\033[0m"
}

function _blue() {
    echo -e "\033[0;36m$1\033[0m"
}

function _green() {
    echo -e "\033[0;32m$1\033[0m"
}

function _red_bold() {
    echo -e "\033[1;31m$1\033[0m"
}

function _yellow_bold() {
    echo -e "\033[1;33m$1\033[0m"
}

function _blue_bold() {
    echo -e "\033[1;36m$1\033[0m"
}

function _green_bold() {
    echo -e "\033[1;32m$1\033[0m"
}

function get_opts(){
    while getopts "D:d:46Ee" opt; do
        case $opt in
            4)
                if [[ "$opt_ipv" == "-6" ]]; then
                    opt_ipv=""
                else
                    opt_ipv="-4"
                fi
                ;;
            6)
                if [[ "$opt_ipv" == "-4" ]]; then
                    opt_ipv=""
                else
                    opt_ipv="-6"
                fi
                ;;
            D|d)
                local opt_dir="${OPTARG%/}"
                if [[ ! -d "$opt_dir" || ! -r "$opt_dir" || ! -w "$opt_dir" ]]; then
                    echo "$(L err03)"
                    exit 1
                else
                    work_dir="${opt_dir}/${work_dir}"
                fi
                ;;
            E|e)
                lang="en"
                opt_lang="-E"
                ;;
            \?)
                echo "$(L err02)"
                ;;
        esac
    done
}

# 运行前检查：root 权限、必需命令、磁盘空间（BenchOS 解压后约 1 GB）
function pre_check(){
    if [[ "$(id -u)" -ne 0 ]]; then
        _red "$(L err_root)"
        exit 1
    fi
    local cmd
    for cmd in curl tar gzip chroot mount umount base64 df; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            _red "$(L err_cmd) $cmd"
            exit 1
        fi
    done
    local parent_dir avail_kb
    parent_dir="$(dirname "$work_dir")"
    avail_kb="$(df -Pk "$parent_dir" 2>/dev/null | awk 'NR==2{print $4}')"
    if [[ -n "$avail_kb" && "$avail_kb" -lt 2097152 ]]; then
        _red "$(L err_space) $(cd "$parent_dir" && pwd)"
        exit 1
    fi
}

function pre_init(){
    mkdir -p "$work_dir"
    cd "$work_dir"
    work_dir="$(pwd)"
}

function pre_cleanup(){
    # incase interupted last time
    clear_mount
    if [[ "$work_dir" == *"caocong"* ]]; then
        rm -rf "${work_dir:?}"/*
    else
        echo "$(L err01)"
        exit 1
    fi
}

function clear_mount(){
    umount "$work_dir/BenchOs/proc/" 2> /dev/null
    umount "$work_dir/BenchOs/sys/" 2> /dev/null
    umount -R "$work_dir/BenchOs/dev/" 2> /dev/null
}

function load_bench_os(){
    cd "$work_dir"
    rm -rf BenchOs

    local url ok=0
    for url in "${bench_os_urls[@]}"; do
        _blue "$(L try_mirror) $url"
        if curl -fL# -o BenchOs.tar.gz "$url" && gzip -t BenchOs.tar.gz 2>/dev/null; then
            ok=1
            break
        fi
        rm -f BenchOs.tar.gz
    done
    if [[ $ok -ne 1 ]]; then
        _red "$(L err_download)"
        exit 1
    fi

    tar -xzf BenchOs.tar.gz
    rm -f BenchOs.tar.gz
    cd "$work_dir/BenchOs"

    mount -t proc /proc proc/
    mount --bind /sys sys/
    mount --rbind /dev dev/
    mount --make-rslave dev

    rm etc/resolv.conf 2>/dev/null
    cp /etc/resolv.conf etc/resolv.conf
    mkdir -p tmp
}

function chroot_run(){
    chroot "$work_dir/BenchOs" /bin/bash -c "$*"
}

function load_3rd_program(){
    chroot_run wget "https://github.com/nxtrace/NTrace-core/releases/download/v1.3.7/nexttrace_linux_$nexttrace_arch" -qO /usr/local/bin/nexttrace
    chroot_run chmod u+x /usr/local/bin/nexttrace
}

# 下载测试脚本到 BenchOS 的 /tmp。
# 优先用本仓库 xykt/ 下的版本：GitHub Actions 每天从 xykt 同步并去广告，校验通过才会更新。
# 本仓库下载失败时，退回 xykt 原版，并在本地做同样的修改（规则同 xykt/patch.sh）：
#   1. show_ad   —— 开头的赞助广告，函数直接返回
#   2. show_tail —— 报告末尾 xykt 的检测量统计和致谢，函数直接返回；结尾由 show_thanks 显示草丛测评的
#   3. upload.check.place —— 不再上传到 xykt，报告里也就没有 Report.Check.Place 链接
#   4. IP 报告的地图链接 —— 换成谷歌地图官方链接
#   5. 报告标题下的项目地址和运行命令 —— 换成草丛测评的
#   6. 报告里的脚本版本号 —— 换成草丛测评的版本号
function fetch_script(){
    local url="$1" name="$2"
    local dest="$work_dir/BenchOs/tmp/$name"
    if curl -fsSL "$raw_file_prefix/xykt/$name" -o "$dest" && grep -q '^show_ad(){ return 0;' "$dest"; then
        return
    fi
    curl -fsSL "$url" | sed -E \
        -e 's/^show_ad\(\)\{/show_ad(){ return 0;/' \
        -e 's/^show_tail\(\)\{/show_tail(){ return 0;/' \
        -e '/upload\.check\.place/s/^/: # /' \
        -e 's#https://check\.place/\$lat,\$lon,\$zoom_level,\$YY#https://www.google.com/maps?q=$lat,$lon\&z=$zoom_level#' \
        -e "s#^shead\[git\]=\".*\"\$#shead[git]=\"https://github.com/$cc_repo\"#" \
        -e "s#^shead\[bash\]=\".*\"\$#shead[bash]=\"bash <(curl -sL $cc_run)\"#" \
        -e "s#^script_version=\".*\"\$#script_version=\"$cc_version\"#" \
        > "$dest"
    [[ -s "$dest" ]] || _red "$(L err_fetch) $url"
}

function run_header(){
    curl -fsSL "$raw_file_prefix/part/header.sh" > "$work_dir/BenchOs/tmp/header.sh"
    chroot_run "CC_VERSION='$cc_version' CC_RUN='$cc_run' CC_SITE='$cc_site' bash /tmp/header.sh"
}

function detect_virt() {
    if [[ -f /run/systemd/container ]]; then
        cat /run/systemd/container
        return
    fi
    if [[ -f /.dockerenv ]]; then
        echo docker
        return
    fi
    if [[ -f /run/.containerenv ]]; then
        echo podman
        return
    fi
    if grep -qa 'lxc' /proc/1/cgroup 2>/dev/null; then
        echo lxc
        return
    fi
    if grep -qa 'hypervisor' /proc/cpuinfo 2>/dev/null; then
        echo kvm
        return
    fi
    echo none
}

############ 以下内容为 HQ 预处理部分（采集宿主机信息，chroot 内看不到） ############
function detect_testdev_type(){
    local dev="$1"
    dev="$(readlink -f "$dev" 2>/dev/null)"
    if [[ "$dev" == /dev/md* ]]; then
        local lvl
        lvl=$(
            awk -v md="$(basename "$dev")" '
                $1 == md {
                    for (i=1;i<=NF;i++)
                        if ($i ~ /^raid[0-9]+$/) {
                            print toupper($i)
                            exit
                        }
                }
            ' /proc/mdstat
        )
        [[ -n "$lvl" ]] && echo "$lvl" || echo "RAID"
        return
    fi
    if [[ "$dev" == /dev/mapper/* || "$dev" == /dev/dm-* ]]; then
        echo "LVM"
        return
    fi
    if lsblk -no TYPE "$dev" 2>/dev/null | grep -qE 'disk|part'; then
        echo "DISK"
        return
    fi
    echo ""
}

function get_testdev_members_from_diskinfo(){
    local dev="$1"
    local i
    for ((i=1; i<=diskinfo[raid_count]; i++)); do
        if [[ "${diskinfo[raid$i.name]}" == "$dev" ]]; then
            echo "${diskinfo[raid$i.devs]}"
            return
        fi
    done
}

function get_testdev_mount_from_diskinfo(){
    local dev="$1"
    local i
    for ((i=1; i<=diskinfo[raid_count]; i++)); do
        if [[ "${diskinfo[raid$i.name]}" == "$dev" ]]; then
            echo "${diskinfo[raid$i.mount]}"
            return
        fi
    done
}

function get_md_mount(){
    local md="$1"
    local mp=""
    mp="$(findmnt -n -o TARGET "/dev/$md" 2>/dev/null)"
    [[ -n "$mp" ]] && { echo "$mp"; return; }
    mp="$(
        lsblk -o NAME,PKNAME,TYPE,MOUNTPOINT -r 2>/dev/null \
        | awk -v md="$md" '$2==md && $4!="" {print $4}' \
        | sort -u | paste -sd "," -
    )"
    [[ -n "$mp" ]] && echo "$mp"
}

function pre_fetch_info(){
    local virt_type="$(detect_virt)"
    declare -gA osinfo
    osinfo[proc]=$(ps -e 2>/dev/null | wc -l | tr -d ' ')
    if command -v loginctl >/dev/null 2>&1; then
        tmpuc="$(loginctl list-users 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')"
        [[ "$tmpuc" -gt 0 ]] && osinfo[user]="$tmpuc"
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        tmpuc="$(stat -f '%Su' /dev/console 2>/dev/null | wc -l | tr -d ' ')"
        [[ "$tmpuc" -gt 0 ]] && osinfo[user]="$tmpuc"
    else
        tmpuc="$(who 2>/dev/null | wc -l | tr -d ' ')"
        [[ "$tmpuc" -gt 0 ]] && osinfo[user]="$tmpuc"
    fi
    if [[ "${virt_type}" =~ ^(docker|podman|lxc|container)$ ]] && [[ "$(ps -p 1 -o comm= 2>/dev/null)" != "systemd" ]]; then
        osinfo[svcr]=""
        osinfo[svct]=""
    elif command -v systemctl >/dev/null 2>&1; then
        osinfo[svcr]=$(systemctl list-units --type=service --state=running 2>/dev/null | grep '\.service' | wc -l | tr -d ' ')
        osinfo[svct]=$(systemctl list-unit-files --type=service 2>/dev/null | grep '\.service' | wc -l | tr -d ' ')
    elif command -v rc-service >/dev/null 2>&1; then
        osinfo[svcr]=$(rc-service -r 2>/dev/null | wc -l | tr -d ' ')
        osinfo[svct]=$(rc-service -l 2>/dev/null | wc -l | tr -d ' ')
    elif [[ "$(uname -s)" == "Darwin" ]] && command -v launchctl >/dev/null 2>&1; then
        osinfo[svcr]=$(launchctl list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
        osinfo[svct]="${osinfo[svcr]}"
    fi
    declare -gA meminfo
    case "${virt_type}" in
        kvm)
            if lsmod 2>/dev/null | grep -q '^virtio_balloon'; then
                meminfo[balloon]=1
            else
                meminfo[balloon]=0
            fi
            if [[ -r /sys/kernel/mm/ksm/run ]] && [[ "$(cat /sys/kernel/mm/ksm/run)" == "1" ]]; then
                meminfo[ksm]=1
            else
                meminfo[ksm]=0
            fi
            ;;
        lxc)
            meminfo[neighbor]=$(ls /sys/devices/virtual/block 2>/dev/null | grep -c '^dm')
            ;;
    esac
    declare -gA diskinfo
    local ridx=0
    if [[ -r /proc/mdstat ]]; then
        while read -r line; do
            if [[ "$line" =~ ^(md[0-9]+)[[:space:]]*:[[:space:]]*active[[:space:]]+([a-z0-9]+)[[:space:]]+(.*)$ ]]; then
                ((ridx++))
                local rname="${BASH_REMATCH[1]}"
                local rlevel="${BASH_REMATCH[2]}"
                local rdevs="${BASH_REMATCH[3]}"
                rlevel="${rlevel^^}"
                rdevs="$(awk '{for(i=1;i<=NF;i++) if ($i ~ /\[[0-9]+\]/) printf "%s ", $i}' <<<"$rdevs")"
                rdevs="${rdevs% }"
                diskinfo["raid$ridx.name"]="$rname"
                diskinfo["raid$ridx.level"]="$rlevel"
                diskinfo["raid$ridx.devs"]="$rdevs"
                diskinfo["raid$ridx.mount"]="$(get_md_mount "$rname")"
            fi
        done < /proc/mdstat
    fi
    diskinfo[raid_count]="$ridx"
    diskinfo[testdir]="${work_dir%/*}"
    diskinfo[testdev]=$(df --output=source "$work_dir" | awk 'NR==2')
    diskinfo[testdev_type]=$(detect_testdev_type "${diskinfo[testdev]}")
    diskinfo[testdev]="${diskinfo[testdev]#/dev/}"
    if [[ "${diskinfo[testdev_type]}" == RAID* ]]; then
        diskinfo[testdev_members]=$(get_testdev_members_from_diskinfo "${diskinfo[testdev]}")
        diskinfo[testdev_mount]=$(get_testdev_mount_from_diskinfo "${diskinfo[testdev]}")
    fi
}
############ 以上内容为 HQ 预处理部分 ############

function run_HardwareQuality(){
    local params=""
    [[ "$run_hardware_quality_test" =~ ^[Ff]$ ]] && params=" -F"
    [[ "$run_hardware_quality_test" =~ ^[Vv]$ ]] && params=" -V"
    pre_fetch_info
    local payload
    payload=$(declare -p osinfo meminfo diskinfo)
    fetch_script https://Hardware.Check.Place hq.sh
    chroot_run "env NQENV=$(printf '%q' "$payload") bash /tmp/hq.sh $opt_lang $params -y -o /result/$hardware_quality_json_filename"
}

function run_ip_quality(){
    fetch_script https://IP.Check.Place iq.sh
    chroot_run bash /tmp/iq.sh $opt_ipv $opt_lang -y -o /result/$ip_quality_json_filename
}

function run_net_quality(){
    local params=""
    [[ "$run_net_quality_test" =~ ^[Ll]$ ]] && params=" -L"
    fetch_script https://Net.Check.Place nq.sh
    chroot_run bash /tmp/nq.sh $opt_ipv $opt_lang $params -y -o /result/$net_quality_json_filename
}

function run_net_trace(){
    fetch_script https://Net.Check.Place nq.sh
    chroot_run bash /tmp/nq.sh $opt_ipv $opt_lang -R -n -S 123 -o /result/$backroute_trace_json_filename
}

# 结果打包成 zip → base64 → POST 到接口
# 接口返回两行：第一行是报告链接，第二行是网站的测评量统计
function upload_result(){
    _green_bold "$(L uploading)"
    chroot_run zip -j -q - "/result/*" > "$work_dir/result.zip"

    local resp
    resp="$(base64 "$work_dir/result.zip" | tr -d '\n' | curl -fsS --max-time 60 -X POST \
        -H "Content-Type: text/plain" \
        -H "X-CC-Version: $cc_version" \
        -H "X-CC-Lang: $lang" \
        --data-binary @- "$cc_api/api/v1/record")"
    if [[ $? -eq 0 && -n "$resp" ]]; then
        report_line="$(sed -n '1p' <<<"$resp")"
        stats_line="$(sed -n '2p' <<<"$resp")"
    else
        _red "$(L upload_fail)"
    fi
}

# 结尾的报告链接和致谢
function show_thanks(){
    local bar="════════════════════════════════════════════════════════════════"
    echo
    _green_bold "$bar"
    [[ -n "$report_line" ]] && echo -e "  \033[1;32m$report_line\033[0m"
    [[ -n "$stats_line" ]] && echo -e "  \033[0;36m$stats_line\033[0m"
    echo -e "  \033[1;33m$(L thanks)\033[0m"
    echo -e "  \033[0;37m$(L thanks_sub) $cc_site\033[0m"
    _green_bold "$bar"
    echo
}

function post_cleanup(){
    chroot_run umount -R /dev &> /dev/null
    clear_mount

    post_check_mount

    rm -rf "$work_dir/BenchOs"

    if [[ "$work_dir" == *"caocong"* ]]; then
        rm -rf "${work_dir:?}"/
    else
        echo "$(L err01)"
        exit 1
    fi
}

# Ctrl+C 或异常退出时也要卸载、清理
function sig_cleanup(){
    trap '' INT TERM SIGHUP EXIT
    _green_bold "$(L cleanup)"
    post_cleanup
    exit 1
}

function post_check_mount(){
    if mount | grep "caocong$current_time" ; then
        echo "$(L clean_fail)" | tee "$work_dir/error.log" >&2
        exit 1
    fi
}

function ask_question(){
    local yellow='\033[1;33m'
    local reset='\033[0m'

    echo -en "${yellow}$(L ask_hq)${reset}"
    read run_hardware_quality_test
    run_hardware_quality_test=${run_hardware_quality_test:-y}

    echo -en "${yellow}$(L ask_iq)${reset}"
    read run_ip_quality_test
    run_ip_quality_test=${run_ip_quality_test:-y}

    echo -en "${yellow}$(L ask_nq)${reset}"
    read run_net_quality_test
    run_net_quality_test=${run_net_quality_test:-y}

    echo -en "${yellow}$(L ask_bt)${reset}"
    read run_net_trace_test
    run_net_trace_test=${run_net_trace_test:-y}
}

function main(){
    start_ascii
    show_promo
    pre_check

    ask_question

    trap 'sig_cleanup' INT TERM SIGHUP EXIT

    _green_bold "$(L cleanup_before)"
    pre_init
    pre_cleanup
    _green_bold "$(L loadbench)"
    load_bench_os

    load_3rd_program

    _green_bold "$(L basicinfo)"

    result_directory=$work_dir/BenchOs/result
    mkdir -p "$result_directory"
    run_header > "$result_directory/$header_info_filename"

    if [[ "$run_hardware_quality_test" =~ ^[YyFfVv]$ ]]; then
        _green_bold "$(L run_hq)"
        run_HardwareQuality | tee "$result_directory/$hardware_quality_filename"
    fi

    if [[ "$run_ip_quality_test" =~ ^[Yy]$ ]]; then
        _green_bold "$(L run_iq)"
        run_ip_quality | tee "$result_directory/$ip_quality_filename"
    fi

    if [[ "$run_net_quality_test" =~ ^[YyLl]$ ]]; then
        _green_bold "$(L run_nq)"
        run_net_quality | tee "$result_directory/$net_quality_filename"
    fi

    if [[ "$run_net_trace_test" =~ ^[Yy]$ ]]; then
        _green_bold "$(L run_bt)"
        run_net_trace | tee "$result_directory/$backroute_trace_filename"
    fi

    upload_result
    show_thanks
    show_promo

    trap - INT TERM SIGHUP EXIT
    _green_bold "$(L cleanup_after)"
    post_cleanup
    exit 0
}

get_opts "$@"
main
