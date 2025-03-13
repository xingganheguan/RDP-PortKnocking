$logFile = "$PSScriptRoot\portknocker_access.json"
$logOutput = "$PSScriptRoot\firewall_log.txt"

# ͳһ��־���
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $message" | Out-File -Append -FilePath $logOutput -Encoding utf8
}

# ɾ������ƥ��ķ���ǽ����
function Remove-AllMatchingFirewallRules {
    Get-NetFirewallRule -DisplayName "PortKnocker-Allow*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
    # Write-Log "ɾ������ƥ��ķ���ǽ����"
}

# �����¼�ļ������ڣ�������
if (-Not (Test-Path $logFile)) {
    # Write-Log "��¼�ļ������ڣ���������ǽ�����顣"
    exit
}

# ��ȡ JSON �ļ�����
try {
    $accessList = Get-Content -Path $logFile -Raw | ConvertFrom-Json
    if (-not $accessList) {
        Write-Log "��¼�ļ�Ϊ�գ�ɾ������ƥ��ķ���ǽ���򣬲�ɾ����¼�ļ���"
        Remove-AllMatchingFirewallRules
        Remove-Item -Path $logFile -ErrorAction SilentlyContinue
        exit
    }
} catch {
    Write-Log "��¼�ļ���ʽ����ɾ������ƥ��ķ���ǽ���򣬲�ɾ����¼�ļ���"
    Remove-AllMatchingFirewallRules
    Remove-Item -Path $logFile -ErrorAction SilentlyContinue
    exit
}

# ��ȡ��ǰʱ��
$currentTime = Get-Date

# ���˳����ڵĹ���
$validRules = @()
foreach ($entry in $accessList) {
    $expiryTime = $null
    $targetIP = $entry.IP
    $ruleName = $entry.Rule
    
    try {
        $expiryTime = [datetime]::ParseExact($entry.Expiry, "yyyy-MM-dd HH:mm:ss", $null)
    } catch {
        Write-Log "ʱ���ʽ�����������: $targetIP"
        continue
    }

    if ($currentTime -ge $expiryTime) {
        Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
        Write-Log "�ѳ��� $targetIP ($ruleName) �� RDP ����Ȩ��"
    } else {
        $validRules += $entry
    }
}

# ���� JSON �ļ�
if ($validRules.Count -eq 0) {
    Write-Log "���й����ѹ��ڣ�ɾ������ƥ��ķ���ǽ���򣬲�ɾ�� JSON ��¼�ļ�: $logFile"
    Remove-AllMatchingFirewallRules
    Remove-Item -Path $logFile -ErrorAction SilentlyContinue
} else {
    $validRules | ConvertTo-Json -Depth 10 | Set-Content -Path $logFile -Encoding UTF8
    # Write-Log "���� JSON ��¼�ļ���������Ȼ��Ч�Ĺ���"
}