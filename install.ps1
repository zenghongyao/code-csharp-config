# Claude 与 Codex 全局规则安装器（Windows PowerShell）

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('Claude', 'Codex', 'All')]
    [string]$Target,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$MaxBackups = 3
$Timestamp = Get-Date -Format 'yyyyMMddHHmmss'

function Write-Info { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn2 { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Err2 { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Show-Help {
    @'
用法：.\install.ps1 [-Target Claude|Codex|All] [-WhatIf] [-Help]

选项：
  -Target    安装目标。Claude 写入 %USERPROFILE%\.claude，Codex 写入 %USERPROFILE%\.codex。
  -WhatIf    预览操作，不修改文件。
  -Help      显示本帮助。

未指定 -Target 时，交互式终端会要求选择目标；非交互环境必须指定 -Target。
已有入口文件和 rules 目录会备份为 *.bak.<时间戳>，最多保留最近 3 份。
'@
}

function Resolve-Target {
    param([string]$SelectedTarget)
    if ($SelectedTarget) { return $SelectedTarget }
    if ([Console]::IsInputRedirected) {
        throw '非交互环境必须通过 -Target 指定 Claude、Codex 或 All。'
    }

    Write-Host '请选择安装目标：'
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
        'Claude' {
            return [pscustomobject]@{
                Name = 'Claude'
                Root = Join-Path $env:USERPROFILE '.claude'
                Source = 'CLAUDE.md'
                Destination = 'CLAUDE.md'
            }
        }
        'Codex' {
            return [pscustomobject]@{
                Name = 'Codex'
                Root = Join-Path $env:USERPROFILE '.codex'
                Source = 'AGENTS.md'
                Destination = 'AGENTS.md'
            }
        }
        default { throw "未知目标：$Name" }
    }
}

function Backup-IfExists {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return }
    if (Test-Path -LiteralPath $Path -PathType Container) {
        $items = @(Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue)
        if ($items.Count -eq 0) { return }
    }

    $backupPath = "$Path.bak.$Timestamp"
    $sequence = 1
    while (Test-Path -LiteralPath $backupPath) {
        $backupPath = "$Path.bak.$Timestamp.$sequence"
        $sequence += 1
    }
    Write-Warn2 "已存在：$Path（备份为 $(Split-Path -Leaf $backupPath)）"
    if ($PSCmdlet.ShouldProcess($Path, "备份到 $backupPath")) {
        Move-Item -LiteralPath $Path -Destination $backupPath -Force
        $oldBackups = Get-ChildItem -Path "$Path.bak.*" -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            Select-Object -Skip $MaxBackups
        foreach ($backup in $oldBackups) {
            Remove-Item -LiteralPath $backup.FullName -Recurse -Force
            Write-Info "清理旧备份：$($backup.Name)"
        }
    }
}

function Install-File {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string]$Source, [string]$Destination)

    $destinationDir = Split-Path -Parent $Destination
    if ($PSCmdlet.ShouldProcess($destinationDir, '创建目录')) {
        New-Item -ItemType Directory -Force -Path $destinationDir | Out-Null
    }
    Backup-IfExists -Path $Destination
    Write-Info "安装：$Destination"
    if ($PSCmdlet.ShouldProcess($Source, "复制到 $Destination")) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
    }
}

function Install-Directory {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string]$Source, [string]$Destination)

    $destinationDir = Split-Path -Parent $Destination
    if ($PSCmdlet.ShouldProcess($destinationDir, '创建目录')) {
        New-Item -ItemType Directory -Force -Path $destinationDir | Out-Null
    }
    Backup-IfExists -Path $Destination
    Write-Info "安装目录：$Destination"
    if ($PSCmdlet.ShouldProcess($Source, "复制到 $Destination")) {
        if (Test-Path -LiteralPath $Destination) {
            Remove-Item -LiteralPath $Destination -Recurse -Force
        }
        Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
    }
}

function Install-Target {
    param([string]$Name)
    $spec = Get-TargetSpec -Name $Name
    $sourceEntry = Join-Path $ScriptDir $spec.Source
    $sourceRules = Join-Path $ScriptDir 'rules'

    if (-not (Test-Path -LiteralPath $sourceEntry -PathType Leaf)) {
        throw "源文件不存在：$sourceEntry"
    }
    if (-not (Test-Path -LiteralPath $sourceRules -PathType Container)) {
        throw "源目录不存在：$sourceRules"
    }

    Write-Host
    Write-Host "安装目标：$($spec.Name)"
    Write-Host "  规则入口：$(Join-Path $spec.Root $spec.Destination)"
    Write-Host "  详细规则：$(Join-Path $spec.Root 'rules')"
    Install-File -Source $sourceEntry -Destination (Join-Path $spec.Root $spec.Destination)
    Install-Directory -Source $sourceRules -Destination (Join-Path $spec.Root 'rules')
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

Write-Host 'Claude 与 Codex 全局规则安装器'
Write-Host "  源目录：$ScriptDir"
Write-Host "  目标：$resolvedTarget"
if ($WhatIfPreference) { Write-Host '  模式：干跑（-WhatIf）' }

$failures = @()
foreach ($name in Get-TargetNames -SelectedTarget $resolvedTarget) {
    try {
        Install-Target -Name $name
    } catch {
        Write-Err2 "$name 安装失败：$($_.Exception.Message)"
        $failures += $name
    }
}

Write-Host
if ($failures.Count -gt 0) {
    Write-Err2 "安装未完全成功，失败目标：$($failures -join '、')"
    exit 1
}

Write-Info '安装完成。重启所选工具后即可生效。'
if ($WhatIfPreference) {
    Write-Warn2 '本次为干跑模式，未实际修改文件。'
}
