# Sobe o app web com Supabase lido do .env local (fora do bundle por segurança).
Set-Location $PSScriptRoot\..

Get-NetTCPConnection -LocalPort 8081 -ErrorAction SilentlyContinue |
  ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }

flutter run -d chrome --web-port=8081 --release --dart-define-from-file=.env
