# Publica o projeto KDA3D no GitHub sem integracao com o Cursor.
param(
    [string]$RepoUrl,
    [string]$Owner,
    [string]$RepoName = "kda3d-calculator",
    [string]$Token = $env:GITHUB_TOKEN,
    [string]$Branch = "main",
    [switch]$Private,
    [switch]$CreateRepo,
    [switch]$InstallGit,
    [string]$CommitMessage = "Initial commit: KDA3D Print Studio (Flutter + Supabase)"
)

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

function Find-Git {
    $cmd = Get-Command git -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @(
        "C:\Program Files\Git\bin\git.exe",
        "C:\Program Files (x86)\Git\bin\git.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\git.exe"
    )
    foreach ($p in $candidates) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

function Ensure-Git {
    $git = Find-Git
    if ($git) { return $git }
    if (-not $InstallGit) {
        throw "Git nao encontrado. Instale em https://git-scm.com/download/win ou use -InstallGit"
    }
    winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
    $git = Find-Git
    if (-not $git) { throw "Git instalado, mas nao encontrado. Reinicie o terminal." }
    return $git
}

function Assert-NoSecrets {
    if (Test-Path ".env") {
        $tracked = & $script:GitExe ls-files --error-unmatch ".env" 2>$null
        if ($LASTEXITCODE -eq 0 -and $tracked) {
            throw "ERRO: .env esta rastreado. Remova com: git rm --cached .env"
        }
    }
}

function New-GitHubRepo {
    param([string]$Name, [bool]$IsPrivate, [string]$AuthToken)

    Write-Step "Criando repositorio $Name no GitHub..."
    $bodyObj = @{
        name        = $Name
        description = "KDA3D Print Studio - calculadora de custos 3D (Flutter + Supabase)"
        private     = $IsPrivate
        auto_init   = $false
    }
    $body = $bodyObj | ConvertTo-Json

    $headers = @{
        Authorization        = "Bearer $AuthToken"
        Accept                 = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }

    $resp = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method Post -Headers $headers -Body $body -ContentType "application/json"
    return $resp.clone_url
}

$script:GitExe = Ensure-Git
Write-Step "Git: $script:GitExe"

if (-not $Token) {
    throw "Token ausente. Defina `$env:GITHUB_TOKEN antes de executar."
}

if ($CreateRepo -or (-not $RepoUrl -and $RepoName)) {
    $CreateRepo = $true
}

if ($CreateRepo) {
    $RepoUrl = New-GitHubRepo -Name $RepoName -IsPrivate:$Private.IsPresent -AuthToken $Token
    Write-Host "Repositorio criado: $RepoUrl" -ForegroundColor Green
}

if (-not $RepoUrl) {
    throw "Informe -RepoUrl ou use -CreateRepo com -RepoName."
}

$parsed = [Uri]$RepoUrl
if ($parsed.Scheme -notin @("https", "http")) {
    throw "Use URL HTTPS, ex: https://github.com/usuario/repo.git"
}
$hostPath = $parsed.Host + $parsed.PathAndQuery
$pushUrl = "https://$Token@$hostPath"

Write-Step "Inicializando repositorio local..."
if (-not (Test-Path ".git")) {
    & $script:GitExe init -b $Branch
}

Assert-NoSecrets

Write-Step "Adicionando arquivos..."
& $script:GitExe add -A
Assert-NoSecrets

$status = & $script:GitExe status --porcelain
if (-not $status) {
    Write-Host "Nada para commitar." -ForegroundColor Yellow
} else {
    Write-Step "Criando commit..."
    & $script:GitExe commit -m $CommitMessage
}

Write-Step "Configurando remote origin..."
$remotes = & $script:GitExe remote 2>$null
if ($remotes -contains "origin") {
    & $script:GitExe remote set-url origin $RepoUrl
} else {
    & $script:GitExe remote add origin $RepoUrl
}

Write-Step "Enviando para GitHub (branch $Branch)..."
& $script:GitExe push -u $pushUrl $Branch

Write-Host "`nPublicado com sucesso!" -ForegroundColor Green
Write-Host "URL: $($RepoUrl -replace '\.git$','')" -ForegroundColor Green
