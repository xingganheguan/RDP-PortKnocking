$logFile = "$PSScriptRoot\portknocker_access.json"
$logOutput = "$PSScriptRoot\firewall_log.txt"

# 统一日志输出
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $message" | Out-File -Append -FilePath $logOutput -Encoding utf8
}

# 删除所有匹配的防火墙规则
function Remove-AllMatchingFirewallRules {
    Get-NetFirewallRule -DisplayName "PortKnocker-Allow*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
    # Write-Log "删除所有匹配的防火墙规则。"
}

# 如果记录文件不存在，则跳过
if (-Not (Test-Path $logFile)) {
    # Write-Log "记录文件不存在，跳过防火墙规则检查。"
    exit
}

# 读取 JSON 文件内容
try {
    $accessList = Get-Content -Path $logFile -Raw | ConvertFrom-Json
    if (-not $accessList) {
        Write-Log "记录文件为空，删除所有匹配的防火墙规则，并删除记录文件。"
        Remove-AllMatchingFirewallRules
        Remove-Item -Path $logFile -ErrorAction SilentlyContinue
        exit
    }
} catch {
    Write-Log "记录文件格式错误，删除所有匹配的防火墙规则，并删除记录文件。"
    Remove-AllMatchingFirewallRules
    Remove-Item -Path $logFile -ErrorAction SilentlyContinue
    exit
}

# 获取当前时间
$currentTime = Get-Date

# 过滤出过期的规则
$validRules = @()
foreach ($entry in $accessList) {
    $expiryTime = $null
    $targetIP = $entry.IP
    $ruleName = $entry.Rule
    
    try {
        $expiryTime = [datetime]::ParseExact($entry.Expiry, "yyyy-MM-dd HH:mm:ss", $null)
    } catch {
        Write-Log "时间格式错误，跳过检查: $targetIP"
        continue
    }

    if ($currentTime -ge $expiryTime) {
        Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
        Write-Log "已撤销 $targetIP ($ruleName) 的 RDP 访问权限"
    } else {
        $validRules += $entry
    }
}

# 更新 JSON 文件
if ($validRules.Count -eq 0) {
    Write-Log "所有规则已过期，删除所有匹配的防火墙规则，并删除 JSON 记录文件: $logFile"
    Remove-AllMatchingFirewallRules
    Remove-Item -Path $logFile -ErrorAction SilentlyContinue
} else {
    $validRules | ConvertTo-Json -Depth 10 | Set-Content -Path $logFile -Encoding UTF8
    # Write-Log "更新 JSON 记录文件，保留仍然有效的规则。"
}