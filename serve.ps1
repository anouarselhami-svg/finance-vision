# Lightweight PowerShell static server with /config endpoint
# Run: powershell -ExecutionPolicy Bypass -File .\serve.ps1
param(
    [int]$Port = 3000
)

Set-Location -Path $PSScriptRoot

Add-Type -AssemblyName System.Net.HttpListener
$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "Serving $PSScriptRoot on http://localhost:$Port"

function Get-MimeType([string]$ext) {
    switch ($ext.ToLower()) {
        ".html" { return "text/html" }
        ".htm" { return "text/html" }
        ".css" { return "text/css" }
        ".js" { return "application/javascript" }
        ".json" { return "application/json" }
        ".png" { return "image/png" }
        ".jpg" { return "image/jpeg" }
        ".jpeg" { return "image/jpeg" }
        ".svg" { return "image/svg+xml" }
        ".ico" { return "image/x-icon" }
        ".txt" { return "text/plain" }
        default { return "application/octet-stream" }
    }
}

function Read-EnvKey([string]$key) {
    $envPath = Join-Path $PSScriptRoot '.env'
    if (-not (Test-Path $envPath)) { return '' }
    Get-Content $envPath | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith('#') -and $line.Contains('=')) {
            $parts = $line -split('=',2)
            $k = $parts[0].Trim()
            $v = $parts[1].Trim().Trim('"').Trim("'")
            if ($k -eq $key) { return $v }
        }
    }
    return ''
}

try {
    while ($true) {
        $ctx = $listener.GetContext()
        $req = $ctx.Request
        $res = $ctx.Response
        $path = $req.Url.AbsolutePath

        if ($path -eq '/' -or $path -eq '') { $path = '/index.html' }

        if ($path -eq '/config') {
            $apiKey = Read-EnvKey 'API_KEY'
            $payload = @{ apiKey = $apiKey } | ConvertTo-Json -Compress
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
            $res.ContentType = 'application/json'
            $res.ContentEncoding = [System.Text.Encoding]::UTF8
            $res.ContentLength64 = $bytes.Length
            $res.OutputStream.Write($bytes, 0, $bytes.Length)
            $res.StatusCode = 200
            $res.Close()
            continue
        }

        $filePath = Join-Path $PSScriptRoot ($path.TrimStart('/').Replace('/', '\'))
        if (-not (Test-Path $filePath)) {
            $res.StatusCode = 404
            $msg = "Not Found"
            $b = [System.Text.Encoding]::UTF8.GetBytes($msg)
            $res.ContentType = 'text/plain'
            $res.ContentLength64 = $b.Length
            $res.OutputStream.Write($b,0,$b.Length)
            $res.Close()
            continue
        }

        $ext = [System.IO.Path]::GetExtension($filePath)
        $mime = Get-MimeType $ext
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $res.ContentType = $mime
        $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
        $res.StatusCode = 200
        $res.Close()
    }
} catch {
    Write-Host "Server stopped: $_"
} finally {
    if ($listener -and $listener.IsListening) { $listener.Stop() }
}
