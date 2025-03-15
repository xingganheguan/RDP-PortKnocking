$uuid = "11c1d446-adf4-46d4-9524-363699e51bdb"
$ip = "1.1.1.1" # 服务器IP
$port = 5005	# 敲门端口
$tcpClient = New-Object System.Net.Sockets.TcpClient
$tcpClient.Connect($ip, $port)
$stream = $tcpClient.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true
$writer.WriteLine($uuid)
$reader = New-Object System.IO.StreamReader($stream)
$response = $reader.ReadLine()
Write-Host "服务器响应: $response"
$writer.Close()
$reader.Close()
$stream.Close()
$tcpClient.Close()
Pause
<#
# 自行修改
Start-Sleep -s 3
C:\Users\Administrator\Desktop\111.rdp
#>
