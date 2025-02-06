#!/usr/bin/env bash

# 设备信息
# 获取智能插座的IP和TOKEN请参考 
# https://github.com/PiotrMachowski/Xiaomi-cloud-tokens-extractor
DEVICE_IP="192.168.1"
DEVICE_TOKEN="设备TOKEN"

# 设备类型详看 python-miio 官方文档
# https://python-miio.readthedocs.io/en/latest/index.html#controlling-modern-miot-devices
# 设备类型一般为 genericmiot 
DEVICE_TYPE="genericmiot"

# 日志文件路径
LOG_FILE="/var/log/miplug_ctl.log"

# Python虚拟环境路径
VENV_PATH="/opt/python-miio-git"

# 检查虚拟环境路径
if [ ! -f "$VENV_PATH/bin/activate" ]; then
    echo "错误：虚拟环境路径 $VENV_PATH 不存在或未正确配置！"
    exit 1
fi

# 最大重试次数和重试间隔
MAX_RETRIES=3
RETRY_DELAY=2

# 日志记录函数
log() {
    local OPERATION=$1
    local RESULT=$2
    local ERROR_MSG=$3

    # 脱敏处理设备令牌
    local MASKED_TOKEN="${DEVICE_TOKEN:0:4}****${DEVICE_TOKEN: -4}"

    # 日志格式：时间戳 | 操作类型 | 设备IP | 脱敏令牌 | 结果 | 错误信息（如果有）
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $OPERATION | 设备IP: $DEVICE_IP | 令牌: $MASKED_TOKEN | 结果: $RESULT | 错误: ${ERROR_MSG:-无}" >> $LOG_FILE
}

# 显示帮助信息
show_help() {
    echo "使用方法: $0 <on|off|info>"
    echo "示例:"
    echo "  $0 on      # 打开插座"
    echo "  $0 off     # 关闭插座"
    echo "  $0 info    # 获取设备信息"
    exit 0
}

# 检查参数
if [ $# -ne 1 ]; then
    show_help
fi

ACTION=$1

# 激活虚拟环境
source "$VENV_PATH/bin/activate"

# 执行操作
case "$ACTION" in
    on|off)
        echo "正在尝试 $ACTION 插座..."
        VALUE=$( [[ "$ACTION" == "on" ]] && echo "True" || echo "False" )
        for ((i=1; i<=MAX_RETRIES; i++)); do
            OUTPUT=$(miiocli $DEVICE_TYPE --ip $DEVICE_IP --token $DEVICE_TOKEN on 2>&1)
            if [ $? -eq 0 ]; then
                echo "操作成功！"
                log "$ACTION" "成功"
                break
            else
                echo "尝试 $i/$MAX_RETRIES 失败，等待 $RETRY_DELAY 秒后重试..."
                sleep $RETRY_DELAY
            fi
        done

        if [ $i -gt $MAX_RETRIES ]; then
            echo "操作失败，请检查设备状态或网络连接。"
            log "$ACTION" "失败" "$OUTPUT"
        fi
        ;;
    info)
        echo "正在查询插座信息..."
        OUTPUT=$(miiocli $DEVICE_TYPE --ip $DEVICE_IP --token $DEVICE_TOKEN info 2>&1)
        if [ $? -eq 0 ]; then
            echo "获取成功：$OUTPUT"
            log "info" "成功" "$OUTPUT"
        else
            echo "获取失败：$OUTPUT"
            log "info" "失败" "$OUTPUT"
        fi
        ;;
    *)
        echo "无效的操作: $ACTION"
        show_help
        ;;
esac

# 退出Python虚拟环境
deactivate
