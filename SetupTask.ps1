# ��ȡ config.json
$configPath = "$PSScriptRoot\config.json"
if (!(Test-Path $configPath)) {
    Write-Host "����: �����ļ� config.json �����ڣ�"
    exit 1
}

$config = Get-Content -Path $configPath | ConvertFrom-Json
$knockPort = $config.ListenPort
$firewallRuleName = "KnockPort(TCP In)"

# ������ǽ�����Ƿ���ڣ�����������򴴽�
if (-not (Get-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName $firewallRuleName `
                        -Direction Inbound `
                        -Action Allow `
                        -Protocol TCP `
                        -LocalPort $knockPort `
                        -Description "������� $knockPort �˿�"
    Write-Host "����ӷ���ǽ����: $firewallRuleName (�˿�: $knockPort)"
} else {
    Write-Host "����ǽ�����Ѵ���: $firewallRuleName"
}

$taskInterval = $config.TaskInterval
$enableLogging = $config.EnableLogging

# ѡ����ʵĽű�
$scriptName = if ($enableLogging) { "RemoveFirewall.ps1" } else { "RemoveFirewall_NoLog.ps1" }
$scriptPath = [System.IO.Path]::Combine($PSScriptRoot, $scriptName)

# ��������
$taskName = "RemoveFirewallRules"

# ʹ�� schtasks ���� Windows 10 �� Server 2022
schtasks /create /tn $taskName /tr "powershell.exe -ExecutionPolicy Bypass -File `"$scriptPath`"" /sc MINUTE /mo $taskInterval /ru "SYSTEM" /RL HIGHEST /F

Write-Host "����ƻ� '$taskName' �����ɹ���ÿ $taskInterval ����ִ��һ��ɾ������ǽ���� (ʹ�� $scriptName)��"
Pause