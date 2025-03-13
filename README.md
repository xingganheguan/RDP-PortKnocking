# Windows RDP 端口敲门（Port Knocking）

## 项目简介

本项目实现了基于端口敲门的 Windows 远程桌面（RDP）访问控制机制。通过监听特定端口，只有提供正确 UUID 的客户端才能动态开放 RDP 端口，提升系统的安全性。

## 功能特性

- 监听特定端口，等待客户端验证 UUID
- 动态添加 Windows 防火墙规则，允许授权 IP 访问 RDP
- 自动删除过期的防火墙规则，确保访问控制
- 通过 `config.json` 配置各项参数，支持是否启用日志功能
- 计划任务自动执行规则清理

## 文件说明

- `config.json` - 配置文件，定义监听端口、UUID、RDP 端口等
- `PortKnocker.ps1` - 监听端口并动态开放 RDP 访问
- `RemoveFirewall_NoLog.ps1` - 移除过期的防火墙规则（不带日志）
- `RemoveFirewall_WithLog.ps1` - 移除过期的防火墙规则（带日志）
- `SetupTask.ps1` - 创建计划任务，定期清理防火墙规则

## 使用方法

1. **配置 **``
   ```json
   {
     "IP": "",
     "ListenPort": 5005,
     "RDPPort": 3389,
     "AccessDuration": 5,
     "UUID": "550e8400-e29b-41d4-a716-446655440000",
     "TaskInterval": 3,
     "EnableLogging": false
   }
   ```
2. **运行 **`` 开启端口监听
3. **客户端发送 UUID 进行敲门**
4. **成功后 RDP 端口临时开放**
5. **定期运行 **``** 清理过期规则**

---

# Windows RDP Port Knocking

## Project Overview

This project implements a port knocking mechanism for Windows Remote Desktop (RDP) access control. By listening on a specific port, only clients providing the correct UUID can dynamically open the RDP port, enhancing security.

## Features

- Listens on a specific port and verifies client UUID
- Dynamically adds Windows firewall rules to allow authorized IPs
- Automatically removes expired firewall rules
- Configurable via `config.json`, supports logging options
- Scheduled task to clean up firewall rules periodically

## File Descriptions

- `config.json` - Configuration file defining listening port, UUID, RDP port, etc.
- `PortKnocker.ps1` - Listens for incoming requests and dynamically opens RDP access
- `RemoveFirewall_NoLog.ps1` - Removes expired firewall rules (without logging)
- `RemoveFirewall_WithLog.ps1` - Removes expired firewall rules (with logging)
- `SetupTask.ps1` - Creates a scheduled task for periodic firewall rule cleanup

## Usage

1. **Configure **``
   ```json
   {
     "IP": "",
     "ListenPort": 5005,
     "RDPPort": 3389,
     "AccessDuration": 5,
     "UUID": "550e8400-e29b-41d4-a716-446655440000",
     "TaskInterval": 3,
     "EnableLogging": false
   }
   ```
2. **Run **`` to start listening
3. **Client sends UUID to knock the port**
4. **Upon success, RDP port is temporarily opened**
5. **Scheduled task runs **``** to clean up expired rules**
