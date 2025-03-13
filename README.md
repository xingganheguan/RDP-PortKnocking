## 原理

基于端口敲门，通过监听特定端口，只有提供正确 UUID 的客户端才能访问服务器远程桌面。

## 文件说明

- `config.json` - 配置文件
- `SetupTask.ps1` - 创建计划任务和开放监听端口的防火墙规则
- `PortKnocker.ps1` - 主要文件、监听端口并动态开放 RDP 访问
- `RemoveFirewall.ps1` - 移除过期的防火墙规则（默认带日志）
- `RemoveFirewall_NoLog.ps1` - 移除过期的防火墙规则（不带日志）

## 使用方法

1. **配置说明**

- `IP` - 默认为空，开放远程桌面给客户端IP。如果设置了，就只开放远程桌面给此IP。
- `ListenPort` - 监听端口，此端口要保持持续开放
- `RDPPort` - 远程桌面端口
- `AccessDuration` - 开放时间（分钟）
- `UUID` - 客户端需要发送此的 UUID 信息
- `TaskInterval` - 根据过期时间每隔 n 分钟清除防火墙规则
- `EnableLogging` - 是否需要生成日志
  
3. 配置文件设置好以后，**运行 **`` SetupTask.ps1 脚本会自动生成规则和计划任务
4. 持续运行 PortKnocker.ps1
