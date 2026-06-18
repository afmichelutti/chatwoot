<#
.SYNOPSIS
  Build, push e (opcional) redeploy da imagem afmichelutti/appio_cw_4130:appio.

.DESCRIPTION
  Fluxo:
    1. Valida que estamos na branch correta e sem mudancas inesperadas.
    2. (opcional) Commita e da push das mudancas pendentes.
    3. docker build da imagem (Dockerfile single-stage baseado em chatwoot/chatwoot:v4.13.0).
    4. docker push pro Docker Hub.
    5. (opcional) Dispara webhook do Portainer pra recriar o container.

.PARAMETER Image
  Nome:tag da imagem. Default: afmichelutti/appio_cw_4130:appio

.PARAMETER Branch
  Branch git esperada. Default: experiment/v4.13.0-merge

.PARAMETER CommitMessage
  Se informado, faz git add -A + commit + push antes do build.

.PARAMETER PortainerWebhook
  URL completa do webhook do Portainer (Stacks > Webhooks). Se informado,
  dispara POST apos o push pra forcar redeploy.

.PARAMETER SkipPush
  So buildar localmente, nao da push.

.PARAMETER SkipBuild
  Pula build + push (uso: so disparar webhook do Portainer).

.EXAMPLE
  # Build + push, sem commit, sem redeploy automatico
  .\scripts\deploy-appio.ps1

.EXAMPLE
  # Commit + push git + build + push imagem + redeploy via Portainer
  .\scripts\deploy-appio.ps1 -CommitMessage "fix: revert 2c3c585f3" -PortainerWebhook "https://portainer.appio.com.br/api/webhooks/abc-123"
#>
[CmdletBinding()]
param(
  [string]$Image = "afmichelutti/appio_cw_4130:appio",
  [string]$Branch = "experiment/v4.13.0-merge",
  [string]$CommitMessage,
  [string]$PortainerWebhook,
  [switch]$SkipPush,
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Step($msg) {
  Write-Host ""
  Write-Host "==> $msg" -ForegroundColor Cyan
}

function Fail($msg) {
  Write-Host "ERRO: $msg" -ForegroundColor Red
  exit 1
}

Step "Validando branch git"
$currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($currentBranch -ne $Branch) {
  Fail "Branch atual e '$currentBranch', esperada '$Branch'. Faca checkout antes."
}
Write-Host "Branch OK: $currentBranch"

if ($CommitMessage) {
  Step "Commitando mudancas pendentes"
  git add -A
  $staged = git diff --cached --name-only
  if (-not $staged) {
    Write-Host "Nada para commitar (working tree limpo)."
  } else {
    Write-Host "Arquivos a commitar:"
    $staged | ForEach-Object { Write-Host "  $_" }
    git commit -m $CommitMessage
    if ($LASTEXITCODE -ne 0) { Fail "git commit falhou." }
    Step "Pushing branch '$Branch' para origin"
    git push origin $Branch
    if ($LASTEXITCODE -ne 0) { Fail "git push falhou." }
  }
} else {
  Step "Verificando working tree"
  $dirty = git status --porcelain
  if ($dirty) {
    Write-Host "Working tree tem mudancas nao commitadas:" -ForegroundColor Yellow
    Write-Host $dirty
    Write-Host "Use -CommitMessage '...' pra commitar e push antes do build, ou commit manualmente." -ForegroundColor Yellow
  }
}

if (-not $SkipBuild) {
  $sha = (git rev-parse --short HEAD).Trim()
  $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $shaTag = "$($Image.Split(':')[0]):$sha"

  Step "Buildando imagem $Image"
  Write-Host "Tags: $Image, $shaTag"
  docker build `
    -t $Image `
    -t $shaTag `
    .
  if ($LASTEXITCODE -ne 0) { Fail "docker build falhou." }

  if (-not $SkipPush) {
    Step "Pushing $Image"
    docker push $Image
    if ($LASTEXITCODE -ne 0) { Fail "docker push (tag appio) falhou. Rodou 'docker login'?" }

    Step "Pushing $shaTag"
    docker push $shaTag
    if ($LASTEXITCODE -ne 0) { Fail "docker push (tag sha) falhou." }
  } else {
    Write-Host "SkipPush ativo - imagem ficou so local." -ForegroundColor Yellow
  }
}

if ($PortainerWebhook) {
  Step "Disparando webhook do Portainer"
  try {
    $response = Invoke-RestMethod -Method Post -Uri $PortainerWebhook -TimeoutSec 30
    Write-Host "Webhook OK. Portainer esta recriando o container."
  } catch {
    Fail "Webhook falhou: $_"
  }
} else {
  Write-Host ""
  Write-Host "Nenhum webhook do Portainer configurado." -ForegroundColor Yellow
  Write-Host "Va no Portainer e force 'Recreate' / 'Pull and redeploy' no stack manualmente," -ForegroundColor Yellow
  Write-Host "ou rode novamente com -PortainerWebhook '<url>'." -ForegroundColor Yellow
}

Step "Done"
Write-Host "Imagem: $Image"
Write-Host "Valide em https://bot.appio.com.br: 3 mensagens consecutivas de um contato novo devem cair em UMA conversa."
