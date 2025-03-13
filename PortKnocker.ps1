# 读取配置文件
$configPath = "$PSScriptRoot\config.json"
$config = Get-Content $configPath | ConvertFrom-Json

$listenPort = $config.ListenPort
$rdpPort = $config.RDPPort
$uuidConfig = $config.UUID
$accessDuration = $config.AccessDuration  # 端口开放时间（分钟）
$logFile = "$PSScriptRoot\portknocker_access.json"

# 创建 TCP 监听器
$listener = New-Object System.Net.Sockets.TcpListener ([System.Net.IPAddress]::Any, $listenPort)
$listener.Start()
Write-Host "监听端口: $listenPort..."

function Write-JsonFile {
    param([string]$filePath, [object]$data)
    $json = $data | ConvertTo-Json -Depth 10
    $json | Set-Content -Path $filePath -Encoding UTF8
}

function Read-JsonFile {
    param([string]$filePath)
    if (-Not (Test-Path $filePath)) { return @() }
    try {
        return Get-Content -Path $filePath -Raw | ConvertFrom-Json
    } catch {
        Write-Host "Error reading JSON. Resetting file." -ForegroundColor Red
        return @()
    }
}

while ($true) {
    $client = $listener.AcceptTcpClient()
    $stream = $client.GetStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $writer = New-Object System.IO.StreamWriter($stream)
    $writer.AutoFlush = $true
    
    $clientIP = $client.Client.RemoteEndPoint.Address.ToString()
    $receivedUUID = $reader.ReadLine().Trim()

    if ($receivedUUID -eq $uuidConfig) {
        # 计算到期时间
        $expiryTime = (Get-Date).AddMinutes($accessDuration).ToString("yyyy-MM-dd HH:mm:ss")
        
        # 使用固定 IP 或者 客户端 IP
        $targetIP = if ($config.IP -eq "") { $clientIP } else { $config.IP }

        $IPParts = $targetIP -split "\."  # 将 IP 按 '.' 分割
        #$RuleName = "PortKnocker-Allow$($IPParts[-1])"  # 规则名为 PortKnocker-Allow + IP 最后两个部分
        #$RuleName = "PortKnocker-Allow$($IPParts[-2]).$($IPParts[-1])"  # 规则名为 PortKnocker-Allow + IP 最后部分
        $RuleName = "PortKnocker-Allow$($IPParts[-2])$($IPParts[-1])"

        # 开放远程桌面端口
        New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $rdpPort -RemoteAddress $targetIP -ErrorAction SilentlyContinue
        <#
        # 读取当前 JSON 记录
        $accessList = Read-JsonFile -filePath $logFile
        
        # 追加新记录
        $accessList += @{ "IP" = $targetIP; "Expiry" = $expiryTime; "Rule" = $RuleName }    
        
        # 写入 JSON 文件
        Write-JsonFile -filePath $logFile -data $accessList
        #>

        # 读取当前 JSON 记录
        $accessList = Read-JsonFile -filePath $logFile
        $accessList = @($accessList)  # 确保它是一个数组        

        # 追加新记录
        $accessList += @{ "IP" = $targetIP; "Expiry" = $expiryTime; "Rule" = $RuleName }            

        # 写入 JSON 文件
        Write-JsonFile -filePath $logFile -data $accessList
        
        # 发送成功信息
        $writer.WriteLine("远程桌面访问已开放，$targetIP 可访问 $rdpPort 端口，有效期至: $expiryTime")
    } else {
        $writer.WriteLine("UUID 错误，访问拒绝。")
    }

    $client.Close()
}