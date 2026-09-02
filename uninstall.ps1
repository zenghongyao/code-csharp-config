# Claude 与 Codex 全局规则卸载器（Windows PowerShell）

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('Claude', 'Codex', 'All')]
    [string]$Target,
    [switch]$Purge,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

function Write-Info { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn2 { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Err2 { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Show-Help {
    @'
用法：.\uninstall.ps1 [-Target Claude|Codex|All] [-Purge] [-WhatIf] [-Help]

选项：
  -Target    卸载目标。未指定时在交互式终端中选择。
  -Purge     删除本包入口、rules 和对应备份，不恢复旧配置。
  -WhatIf    预览操作，不修改文件。
  -Help      显示本帮助。

默认行为恢复最近备份；没有备份时只删除本包安装的入口与 rules。
非交互环境必须指定 -Target。
'@
}

function Resolve-Target {
    param([string]$SelectedTarget)
    if ($SelectedTarget) { return $SelectedTarget }
    if ([Console]::IsInputRedirected) {
        throw '非交互环境必须通过 -Target 指定 Claude、Codex 或 All。'
    }
    Write-Host '请选择卸载目标：'
    Write-Host '  1. Claude'
    Write-Host '  2. Codex'
    Write-Host '  3. Claude 和 Codex'
    $choice = Read-Host '输入 1、2 或 3'
    switch ($choice) {
        '1' { return 'Claude' }
        '2' { return 'Codex' }
        '3' { return 'All' }
        default { throw '无效选择，请重新执行并输入 1、2 或 3。' }
    }
}

function Get-TargetNames {
    param([string]$SelectedTarget)
    if ($SelectedTarget -eq 'All') { return @('Claude', 'Codex') }
    return @($SelectedTarget)
}

function Get-TargetSpec {
    param([string]$Name)
    switch ($Name) {
        'Claude' { return [pscustomobject]@{ Name = 'Claude'; Root = Join-Path $env:USERPROFILE '.claude'; Entry = 'CLAUDE.md' } }
        'Codex' { return [pscustomobject]@{ Name = 'Codex'; Root = Join-Path $env:USERPROFILE '.codex'; Entry = 'AGENTS.md' } }
        default { throw "未知目标：$Name" }
    }
}

function Remove-Path {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        Write-Info "删除：$Path"
        if ($PSCmdlet.ShouldProcess($Path, '删除')) {
            Remove-Item -LiteralPath $Path -Recurse -Force
        }
    }
}

function Restore-LatestBackup {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string]$TargetPath)

    $latest = Get-ChildItem -Path "$TargetPath.bak.*" -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        Select-Object -First 1
    if ($null -eq $latest) { return $false }

    Write-Info "恢复备份：$($latest.FullName) -> $TargetPath"
    if ($PSCmdlet.ShouldProcess($TargetPath, '删除现有内容并恢复备份')) {
        if (Test-Path -LiteralPath $TargetPath) {
            Remove-Item -LiteralPath $TargetPath -Recurse -Force
        }
        Rename-Item -LiteralPath $latest.FullName -NewName (Split-Path -Leaf $TargetPath) -Force
    }
    return $true
}

function Remove-AllBackups {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string]$TargetPath)
    Get-ChildItem -Path "$TargetPath.bak.*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Info "清理备份：$($_.FullName)"
        if ($PSCmdlet.ShouldProcess($_.FullName, '删除备份')) {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force
        }
    }
}

function Uninstall-Target {
    param([string]$Name)
    $spec = Get-TargetSpec -Name $Name
    $entryPath = Join-Path $spec.Root $spec.Entry
    $rulesPath = Join-Path $spec.Root 'rules'

    Write-Host
    Write-Host "卸载目标：$($spec.Name)"
    if (-not (Test-Path -LiteralPath $spec.Root -PathType Container)) {
        Write-Warn2 "目标目录不存在：$($spec.Root)，无需卸载。"
        return
    }

    if ($Purge) {
        Remove-Path -Path $entryPath
        Remove-Path -Path $rulesPath
        Remove-AllBackups -TargetPath $entryPath
        Remove-AllBackups -TargetPath $rulesPath
    }
    else {
        if (-not (Restore-LatestBackup -TargetPath $entryPath)) {
            Remove-Path -Path $entryPath
        }
        if (-not (Restore-LatestBackup -TargetPath $rulesPath)) {
            Remove-Path -Path $rulesPath
        }
        Remove-AllBackups -TargetPath $entryPath
        Remove-AllBackups -TargetPath $rulesPath
    }

    if ((Get-ChildItem -LiteralPath $spec.Root -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
        Remove-Path -Path $spec.Root
    }
}

if ($Help) {
    Show-Help
    exit 0
}

try {
    $resolvedTarget = Resolve-Target -SelectedTarget $Target
} catch {
    Write-Err2 $_.Exception.Message
    exit 1
}

Write-Host 'Claude 与 Codex 全局规则卸载器'
Write-Host "  目标：$resolvedTarget"
if ($Purge) { Write-Host '  模式：完全删除（含备份）' }
if ($WhatIfPreference) { Write-Host '  模式：干跑（-WhatIf）' }

$failures = @()
foreach ($name in Get-TargetNames -SelectedTarget $resolvedTarget) {
    try {
        Uninstall-Target -Name $name
    } catch {
        Write-Err2 "$name 卸载失败：$($_.Exception.Message)"
        $failures += $name
    }
}

Write-Host
if ($failures.Count -gt 0) {
    Write-Err2 "卸载未完全成功，失败目标：$($failures -join '、')"
    exit 1
}

Write-Info '卸载完成。'
if ($WhatIfPreference) {
    Write-Warn2 '本次为干跑模式，未实际修改文件。'
}
