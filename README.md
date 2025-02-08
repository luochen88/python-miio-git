# 玩客云 PiKVM 的 Python-miio-git 虚拟环境

本包是为玩客云 PiKVM 打包的 `python-miio-git` 虚拟环境。

源项目地址: [python-miio](https://github.com/rytilahti/python-miio)

## 使用说明

1. **解压缩压缩包**  
   将本压缩包解压到 `/opt` 目录下：
   ```bash
   sudo mkdir -p /opt/python-miio-git
   sudo tar -zxvf python-miio-git.tar.gz -C /opt/python-miio-git

2. **修改配置文件**  
   修改 `miplug.sh` 文件，填写智能插座的 IP 和 TOKEN。获取智能插座的 IP 和 TOKEN 请参考 [Xiaomi-cloud-tokens-extractor](https://github.com/PiotrMachowski/Xiaomi-cloud-tokens-extractor),[Obtaining tokens](https://python-miio.readthedocs.io/en/latest/discovery.html#obtaining-tokens)

   默认设备类型: `genericmiot`。设备类型详情请参见 `python-miio` 官方文档：[Controlling Modern MiOT Devices](https://python-miio.readthedocs.io/en/latest/index.html#controlling-modern-miot-devices)。
3. **复制脚本文件**  
   复制 `miplug.sh` 到 `/etc/kvmd/` 目录：
   ```bash
   sudo cp miplug.sh /etc/kvmd/
   sudo chmod +x /etc/kvmd/miplug.sh

4. **配置日志权限**  
   创建日志文件并修改权限：
   ```bash
   sudo touch /var/log/miplug.log
   sudo chown kvmd:kvmd /var/log/miplug.log
   sudo chmod 664 /var/log/miplug.log

5. **备份配置文件**  
   备份 `ovreeide.yaml` 文件：
   ```bash
   sudo cp /etc/kvmd/ovreeide.yaml /etc/kvmd/ovreeide.yaml.backup

6. **修改 override.yaml**  
   根据 `override.yaml` 的参考，修改 `/etc/kvmd/override.yaml` 文件，添加对应参数：

   ```yaml
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

   - ["#智能插座:", start_power|开, stop_power|关] # UI

7. **重启服务**  
   重启 `kvmd` 和 `kvmd-nginx` 服务：
   ```bash
   systemctl restart kvmd kvmd-nginx
