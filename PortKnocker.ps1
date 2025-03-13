# ��ȡ�����ļ�
$configPath = "$PSScriptRoot\config.json"
$config = Get-Content $configPath | ConvertFrom-Json

$listenPort = $config.ListenPort
$rdpPort = $config.RDPPort
$uuidConfig = $config.UUID
$accessDuration = $config.AccessDuration  # �˿ڿ���ʱ�䣨���ӣ�
$logFile = "$PSScriptRoot\portknocker_access.json"

# ���� TCP ������
$listener = New-Object System.Net.Sockets.TcpListener ([System.Net.IPAddress]::Any, $listenPort)
$listener.Start()
Write-Host "�����˿�: $listenPort..."

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
        # ���㵽��ʱ��
        $expiryTime = (Get-Date).AddMinutes($accessDuration).ToString("yyyy-MM-dd HH:mm:ss")
        
        # ʹ�ù̶� IP ���� �ͻ��� IP
        $targetIP = if ($config.IP -eq "") { $clientIP } else { $config.IP }

        $IPParts = $targetIP -split "\."  # �� IP �� '.' �ָ�
        #$RuleName = "PortKnocker-Allow$($IPParts[-1])"  # ������Ϊ PortKnocker-Allow + IP �����������
        #$RuleName = "PortKnocker-Allow$($IPParts[-2]).$($IPParts[-1])"  # ������Ϊ PortKnocker-Allow + IP ��󲿷�
        $RuleName = "PortKnocker-Allow$($IPParts[-2])$($IPParts[-1])"

        # ����Զ������˿�
        New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $rdpPort -RemoteAddress $targetIP -ErrorAction SilentlyContinue
        <#
        # ��ȡ��ǰ JSON ��¼
        $accessList = Read-JsonFile -filePath $logFile
        
        # ׷���¼�¼
        $accessList += @{ "IP" = $targetIP; "Expiry" = $expiryTime; "Rule" = $RuleName }    
        
        # д�� JSON �ļ�
        Write-JsonFile -filePath $logFile -data $accessList
        #>

        # ��ȡ��ǰ JSON ��¼
        $accessList = Read-JsonFile -filePath $logFile
        $accessList = @($accessList)  # ȷ������һ������        

        # ׷���¼�¼
        $accessList += @{ "IP" = $targetIP; "Expiry" = $expiryTime; "Rule" = $RuleName }            

        # д�� JSON �ļ�
        Write-JsonFile -filePath $logFile -data $accessList
        
        # ���ͳɹ���Ϣ
        $writer.WriteLine("Զ����������ѿ��ţ�$targetIP �ɷ��� $rdpPort �˿ڣ���Ч����: $expiryTime")
    } else {
        $writer.WriteLine("UUID ���󣬷��ʾܾ���")
    }

    $client.Close()
}