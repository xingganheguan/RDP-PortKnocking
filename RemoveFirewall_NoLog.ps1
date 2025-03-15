# 版本 1: 不带日志输出

$logFile = "$PSScriptRoot\portknocker_access.json"

# 删除所有匹配的防火墙规则
function Remove-AllMatchingFirewallRules {
    Get-NetFirewallRule -DisplayName "PortKnocker-Allow*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
}

# 如果记录文件不存在，则跳过
if (-Not (Test-Path $logFile)) {
    exit
}

# 读取 JSON 文件内容
try {
    $accessList = Get-Content -Path $logFile -Raw | ConvertFrom-Json
    if (-not $accessList) {
        Remove-AllMatchingFirewallRules
        Remove-Item -Path $logFile -ErrorAction SilentlyContinue
        exit
    }
} catch {
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
        continue
    }

    if ($currentTime -ge $expiryTime) {
        Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
    } else {
        $validRules += $entry
    }
}

# 更新 JSON 记录文件
if ($validRules.Count -eq 0) {
    Remove-AllMatchingFirewallRules
    Remove-Item -Path $logFile -ErrorAction SilentlyContinue
} else {
    $validRules | ConvertTo-Json -Depth 10 | Set-Content -Path $logFile -Encoding UTF8
}