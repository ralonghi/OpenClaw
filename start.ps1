$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Test-Path ".env")) {
  Copy-Item ".env.example" ".env"
}

$envContent = Get-Content ".env" -Raw
if ($envContent -notmatch "(?m)^OPENCLAW_GATEWAY_TOKEN=.+") {
  $token = -join ((1..32) | ForEach-Object { "{0:x2}" -f (Get-Random -Maximum 256) })
  $envContent = $envContent -replace "(?m)^OPENCLAW_GATEWAY_TOKEN=.*", "OPENCLAW_GATEWAY_TOKEN=$token"
  Set-Content -Path ".env" -Value $envContent -NoNewline
}

Write-Host "Subindo o OpenClaw..."
docker compose up -d --pull missing openclaw-gateway
if ($LASTEXITCODE -ne 0) {
  throw "Falha ao subir o Docker Compose. Confirme que o Docker Desktop esta em execucao."
}

$tokenLine = Select-String -Path ".env" -Pattern "^OPENCLAW_GATEWAY_TOKEN=(.+)$"
$token = $tokenLine.Matches.Groups[1].Value

Write-Host ""
Write-Host "OpenClaw no ar."
Write-Host "Control UI: http://127.0.0.1:18789/"
Write-Host "Token:      $token"
Write-Host ""
Write-Host "Cole o token em Settings na Control UI."
Write-Host "CLI: docker compose --profile cli run --rm openclaw-cli --help"
