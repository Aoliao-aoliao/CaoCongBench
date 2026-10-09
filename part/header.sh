#!/bin/bash
# 报告头，会出现在网页报告的最上方
# 版本号、命令、网址由主脚本 CaoCong.sh 通过环境变量传入

# 报告里的推广位：填一行文字即可（比如频道、群、优惠链接），留空则不显示
PROMO=""

HEADING_DATE="$(TZ='Asia/Shanghai' date +'%Y-%m-%d %H:%M:%S CST')"
echo -ne "\e[0;32m"
cat <<-EOF
########################################################################
                           草丛测评 CaoCong Bench
                  bash <(curl -sL ${CC_RUN})
        报告时间：$HEADING_DATE  脚本版本：${CC_VERSION}
        网站：${CC_SITE}
EOF
[[ -n "$PROMO" ]] && echo "        $PROMO"
echo "########################################################################"
echo -ne "\033[0m"
