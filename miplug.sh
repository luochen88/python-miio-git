#!/usr/bin/env bash

# 设备信息
# 获取智能插座的IP和TOKEN请参考 
# https://github.com/PiotrMachowski/Xiaomi-cloud-tokens-extractor
DEVICE_IP="192.168.1.1"
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
        VALUE=$( [[ "$ACTION" == "on" ]] && echo "True" || echo "False" )
        ACTION_CHINESE=$( [[ "$ACTION" == "on" ]] && echo "打开" || echo "关闭" )
        echo "正在尝试$ACTION_CHINESE插座..."

        OUTPUT=$(miiocli $DEVICE_TYPE --ip $DEVICE_IP --token $DEVICE_TOKEN raw_command set_properties "[{'siid': 2, 'piid': 1, 'value': $VALUE}]" 2>&1)
        if [ $? -eq 0 ] && [[ "$OUTPUT" == *"成功"* ]]; then  # 检查输出内容
            echo "操作成功！"
            log "$ACTION" "成功"  # 仍然记录日志
        else
            echo "$OUTPUT"
            echo "操作失败，请检查设备ip token和网络连接。"
            log "$ACTION" "失败" "$OUTPUT"  # 仍然记录日志
        fi
        ;;
    status)
        echo "正在查询插座状态..."
        OUTPUT=$(miiocli $DEVICE_TYPE --ip $DEVICE_IP --token $DEVICE_TOKEN raw_command get_properties "[{'siid': 2, 'piid': 1}]" 2>&1)
        if [ $? -eq 0 ] && [[ "$OUTPUT" == *"状态信息"* ]]; then  # 检查输出内容
            echo "查询成功：$OUTPUT"
            log "status" "成功" "状态: $OUTPUT"
        else
            echo "查询失败：$OUTPUT"
            echo "操作失败，请检查设备ip token和网络连接。"
            log "status" "失败" "$OUTPUT"
        fi
        ;;
    info)
        echo "正在获取设备信息..."
        OUTPUT=$(miiocli $DEVICE_TYPE --ip $DEVICE_IP --token $DEVICE_TOKEN info 2>&1)
        if [ $? -eq 0 ] && [[ "$OUTPUT" == *"设备信息"* ]]; then  # 检查输出内容
            echo "获取成功：$OUTPUT"
            log "info" "成功" "$OUTPUT"
        else
            echo "获取失败：$OUTPUT"
            echo "操作失败，请检查设备ip token和网络连接。"
            log "info" "失败" "$OUTPUT"
        fi
        ;;
    *)
        echo "无效的操作: $ACTION"
        show_help
        ;;
esac
