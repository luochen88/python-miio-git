# 本包是为玩客云PiKVM打包的 python-miio-git 虚拟环境
# 源项目地址 : https://github.com/rytilahti/python-miio

# 使用说明
# 将本压缩包解压到 /opt 目录下

tar -zcvf python-miio-git.tar.gz

# 修改 miplug.sh 填写智能插座的IP和TOKEN
# 获取智能插座的IP和TOKEN请参考 
# https://github.com/PiotrMachowski/Xiaomi-cloud-tokens-extractor
# 默认设备类型 : genericmiot 
# 设备类型详看 python-miio 官方文档
# https://python-miio.readthedocs.io/en/latest/index.html#controlling-modern-miot-devices

# 复制 miplug.sh 到 /etc/kvmd/ 目录下

cp miplug.sh /etc/kvmd/
chmod -x /etc/kvmd/miplug.sh

# 备份 ovreeide.yaml
cp /etc/kvmd/ovreeide.yaml /etc/kvmd/ovreeide.yaml.backup
# 参考 override.yaml 修改 /etc/kvmd/override.yaml 添加对应参数

            miplug_on: # 米家智能插座控制开
                type: cmd
                cmd: [/bin/bash, /etc/kvmd/miplug.sh, on]
            miplug_off: # 米家智能插座控制关
                type: cmd
                cmd: [/bin/bash, /etc/kvmd/miplug.sh, off]

            start_power: # 上电
                driver: miplug_on
                pin: 0
                mode: output
                switch: false
            stop_power: # 断电
                driver: miplug_off
                pin: 0
                mode: output
                switch: false

                - ["#智能插座:",start_power|开,stop_power|关] #UI

# 重启kvmd kvmd-nginx
systemctl restart kvmd kvmd-nginx
