[CmdletBinding()]
param(
    [string]$Remote = 'origin',
    [string]$Branch = 'main',
    [string]$Message = ''
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

# Refresh the published skill folders from the local skill sources before committing.
$architectSource = $repo
$architectTarget = Join-Path $repo 'skills\video-script-architect'
Copy-Item (Join-Path $architectSource 'SKILL.md') (Join-Path $architectTarget 'SKILL.md') -Force
Copy-Item (Join-Path $architectSource 'references\*.md') (Join-Path $architectTarget 'references') -Force

$templateSource = 'C:\Users\Windows\.codex\skills\playable-script-template'
$templateTarget = Join-Path $repo 'skills\playable-script-template'
if (Test-Path (Join-Path $templateSource 'SKILL.md')) {
    Copy-Item (Join-Path $templateSource 'SKILL.md') (Join-Path $templateTarget 'SKILL.md') -Force
    if (Test-Path (Join-Path $templateSource 'references')) {
        New-Item -ItemType Directory -Force -Path (Join-Path $templateTarget 'references') | Out-Null
        Copy-Item (Join-Path $templateSource 'references\*.md') (Join-Path $templateTarget 'references') -Force
    }
}

if (-not (Test-Path (Join-Path $repo '.git'))) {
    throw "Not a Git repository: $repo"
}

$remoteUrl = git remote get-url $Remote 2>$null
if (-not $remoteUrl) {
    throw "Remote '$Remote' is not configured. Add it with: git remote add $Remote <GitHub-URL>"
}

git fetch $Remote --prune
$currentBranch = git branch --show-current
if (-not $currentBranch) {
    git checkout -B $Branch
    $currentBranch = $Branch
}
if ($currentBranch -ne $Branch) {
    git checkout -B $Branch
}

git add -- 'skills' 'scripts'
$pending = git status --short
if ($pending) {
    if (-not $Message) {
        $Message = "Update skills $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    }
    git commit -m $Message
}

git pull --rebase $Remote $Branch
git push $Remote $Branch
Write-Output "Synced $Branch to $remoteUrl"
