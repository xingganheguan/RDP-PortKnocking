## 写脚本起因
windows的小鸡面对暴力破解，设置白名单是个好办法，但是像IP经常变动的家庭宽带，就不实用了。因此跟chatgpt友好交流了一天时间，写出了个`端口敲门给特定IP开门`的脚本。

## 原理

基于端口敲门，通过监听特定端口，只有提供正确 UUID 的客户端才能访问服务器远程桌面。

## ★ 注意事项 ★
小鸡装好windows以后，都有一条连接远程桌面的默认规则（TCP），不要删，设置白名单给一个或更多自用vps的IP（能连就行），脚本失效，可以留个后路，以防自己追悔莫及。当然小鸡后台VNC好用的可以忽略这条

## 文件说明

- `config.json` - 配置文件
- `SetupTask.ps1` - 创建计划任务和开放监听端口的防火墙规则
- `PortKnocker.ps1` - 主要文件、监听端口并动态开放 RDP 访问
- `RemoveFirewall.ps1` - 移除过期的防火墙规则（默认带日志）
- `RemoveFirewall_NoLog.ps1` - 移除过期的防火墙规则（不带日志）
---
- `knock.ps1` 客户端敲门的脚本

## 使用方法

1. **配置说明**

- `IP` - 默认为空，开放远程桌面给客户端IP。如果设置了，就只开放远程桌面给此IP。
- `ListenPort` - 监听端口，此端口要保持持续开放
- `RDPPort` - 远程桌面端口
- `AccessDuration` - 开放时间（分钟）
- `UUID` - 客户端需要发送此的 UUID 信息
- `TaskInterval` - 根据过期时间每隔 n 分钟清除防火墙规则
- `EnableLogging` - 是否需要生成日志
  
3. 配置文件设置好以后，运行`SetupTask.ps1` 脚本会自动生成规则和计划任务
4. 持续运行 PortKnocker.ps1（可注册为服务）

## 使用 NSSM 将 PowerShell 脚本注册为 Windows 服务

### 1. 下载 NSSM
从 [NSSM 官网](https://nssm.cc/) 下载 `nssm.exe`，并解压到某个目录（如 `D:\nssm`）。

### 2. 准备 PowerShell 脚本
假设你的 PowerShell 脚本路径为：`D:\portknock\PortKnocker.ps1`
它包含你希望作为服务运行的代码。

### 3. 使用 NSSM 注册服务
打开PowerShell 或 CMD 输入命令 ：

```cmd
cd /d D:\nssm

nssm install PortKnocker
```
会弹出一个 GUI 窗口，在 Application 选项卡填写以下内容：

> Path: 选择 powershell.exe（通常在C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe）。
> 
> Startup directory: 选择脚本所在目录，如 D:\portknock。
> 
> Arguments: 指定如下内容：
> 
> -ExecutionPolicy Bypass -File D:\portknock\PortKnocker.ps1

切换 Details 选项卡
> Display name: 显示名称 输入PortKnocker service
> 

> 
> Dsecription: 描述
> 
> Startup type ：启动类型. Automatic -自动

点击 Install service。


### 4. 启动服务
注册完成后，在 PowerShell 中运行以下命令启动服务：

```powershell
Start-Service PortKnocker
```
或者可以在`服务`面板中手动启动

这样，你的 PowerShell 脚本就成功注册为 Windows 服务，并能随 Windows 自动运行！ 🚀

### NSSM 可用命令
```powershell
卸载服务： nssm remove MyPowerShellService confirm

启动服务： nssm start <servicename>

停止服务： nssm stop <servicename>

重启服务： nssm restart <servicename>

暂停/继续服务
nssm pause <servicename>
nssm continue <servicename>

查看服务状态：nssm status <servicename>
```
参考： [使用NSSM注册Windows服务](https://www.cnblogs.com/lichu-lc/p/10263799.html)
