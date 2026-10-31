<#
.SYNOPSIS
  Install the requirements-ledger-cli skill into an agent skills directory.
.DESCRIPTION
  Copies the skill directory (SKILL.md; excludes installer scripts) into <target>\requirements-ledger-cli.
  Without -Target, probes common skills directories and falls back to
  $HOME\.agents\skills.
.EXAMPLE
  .\install.ps1
.EXAMPLE
  .\install.ps1 -Target "$HOME\.Codex\skills"
#>
param(
    [string]$Target
)

$ErrorActionPreference = 'Stop'
$SkillName = 'requirements-ledger-cli'
$Source = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

if (-not (Test-Path (Join-Path $Source 'SKILL.md'))) {
    throw "SKILL.md not found under $Source"
}

if (-not $Target) {
    $candidates = @(
        (Join-Path $HOME '.agents\skills'),
        (Join-Path $HOME '.Codex\skills'),
        (Join-Path $HOME '.claude\skills')
    )
    $Target = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $Target) {
        $Target = Join-Path $HOME '.agents\skills'
        Write-Host "no known skills directory found; creating $Target"
    }
}

$Target = [System.IO.Path]::GetFullPath($Target)
New-Item -ItemType Directory -Force -Path $Target | Out-Null
$Dest = Join-Path $Target $SkillName

if (Test-Path $Dest) {
    Write-Host "replacing existing $Dest"
    Remove-Item -Recurse -Force $Dest
}

Copy-Item -Recurse -Force $Source $Dest
Remove-Item -Recurse -Force (Join-Path $Dest 'scripts') -ErrorAction SilentlyContinue

Write-Host "installed: $(Join-Path $Dest 'SKILL.md')"
Write-Host "verify:    Test-Path (Join-Path '$Dest' 'SKILL.md')"
Write-Host "next:      restart the agent session so the skill catalog reloads"
