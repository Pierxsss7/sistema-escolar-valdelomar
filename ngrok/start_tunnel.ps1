$log = "C:\Users\ALEXANDER\Documents\OpenCode\ngrok\tunnel_url.txt"
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "C:\Users\ALEXANDER\Documents\OpenCode\ngrok\cloudflared.exe"
$psi.Arguments = "tunnel --url http://localhost:8000"
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.WorkingDirectory = "C:\Users\ALEXANDER\Documents\OpenCode\ngrok"
$p = [System.Diagnostics.Process]::Start($psi)
$out = $p.StandardOutput.ReadToEnd()
$err = $p.StandardError.ReadToEnd()
$all = $out + "`n" + $err
$all | Out-File -FilePath $log -Encoding UTF8
