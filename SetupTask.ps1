# 读取 config.json
$configPath = "$PSScriptRoot\config.json"
if (!(Test-Path $configPath)) {
    Write-Host "错误: 配置文件 config.json 不存在！"
    exit 1
}

$config = Get-Content -Path $configPath | ConvertFrom-Json
$knockPort = $config.ListenPort
$firewallRuleName = "KnockPort(TCP In)"

# 检查防火墙规则是否存在，如果不存在则创建
if (-not (Get-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName $firewallRuleName `
                        -Direction Inbound `
                        -Action Allow `
                        -Protocol TCP `
                        -LocalPort $knockPort `
                        -Description "允许访问 $knockPort 端口"
    Write-Host "已添加防火墙规则: $firewallRuleName (端口: $knockPort)"
} else {
    Write-Host "防火墙规则已存在: $firewallRuleName"
}

$taskInterval = $config.TaskInterval
$enableLogging = $config.EnableLogging

# 选择合适的脚本
$scriptName = if ($enableLogging) { "RemoveFirewall.ps1" } else { "RemoveFirewall_NoLog.ps1" }
$scriptPath = [System.IO.Path]::Combine($PSScriptRoot, $scriptName)

# 任务名称
$taskName = "RemoveFirewallRules"

# 使用 schtasks 兼容 Windows 10 和 Server 2022
schtasks /create /tn $taskName /tr "powershell.exe -ExecutionPolicy Bypass -File `"$scriptPath`"" /sc MINUTE /mo $taskInterval /ru "SYSTEM" /RL HIGHEST /F

Write-Host "任务计划 '$taskName' 创建成功，每 $taskInterval 分钟执行一次删除防火墙规则 (使用 $scriptName)。"
Pause