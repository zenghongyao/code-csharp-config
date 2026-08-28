# 一键安装 Claude Code 全局配置（Windows PowerShell）
# 用法：
#   .\install.ps1              正常安装
#   .\install.ps1 -WhatIf     预览变更，不实际操作
#   .\install.ps1 -Help        查看帮助

[CmdletBinding(SupportsShouldProcess = $true)]
param()

$ErrorActionPreference = 'Stop'

# 源目录 = 脚本所在目录（不依赖调用时的 cwd）
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetDir = Join-Path $env:USERPROFILE '.claude'
$MaxBackups = 3
$Timestamp = Get-Date -Format 'yyyyMMddHHmmss'

# 颜色（仅当输出到终端时启用）
function Write-Info  { param($m) if ($Host.UI.SupportsVirtualTerminal) { Write-Host "[OK] $m" -ForegroundColor Green } else { Write-Host "[OK] $m" } }
function Write-Warn2 { param($m) if ($Host.UI.SupportsVirtualTerminal) { Write-Host "[WARN] $m" -ForegroundColor Yellow } else { Write-Host "[WARN] $m" } }
function Write-Err2  { param($m) if ($Host.UI.SupportsVirtualTerminal) { Write-Host "[ERROR] $m" -ForegroundColor Red } else { Write-Host "[ERROR] $m" } }

function Show-Help {
    @'
用法：.\install.ps1 [选项]

选项：
  -WhatIf     预览将要执行的操作，不实际修改文件
  -Help       显示本帮助

说明：
  - 源目录：脚本所在目录（包含 CLAUDE.md 和 rules/）
  - 目标目录：%USERPROFILE%\.claude
  - 已存在的目标文件会自动备份为 *.bak.<时间戳>，最多保留最近 3 个备份
'@
}

# 备份已存在的文件/目录，保留最近 N 个同名备份
# 只对"文件"或"非空目录"备份：避免 Install-Dir 创建的空目录占位被误备份
function Backup-IfExists {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param($Path)
    if (-not (Test-Path $Path)) { return }
    if (Test-Path -PathType Container $Path) {
        # 是目录：必须非空才备份
        $items = @(Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue)
        if ($items.Count -eq 0) { return }
    }
    $bak = "$Path.bak.$Timestamp"
    Write-Warn2 "已存在：$Path（备份为 $(Split-Path -Leaf $bak)）"
    if ($PSCmdlet.ShouldProcess($Path, "备份到 $bak")) {
        Move-Item -Path $Path -Destination $bak -Force
        # 清理超出数量限制的旧备份
        $pattern = "$Path.bak.*"
        $oldBackups = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -Skip $MaxBackups
        foreach ($old in $oldBackups) {
            Remove-Item -Path $old.FullName -Force
            Write-Info "清理旧备份：$($old.Name)"
        }
    }
}

# 复制单个文件（先备份再覆盖）
function Install-File {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string]$Src, [string]$Dst)
    if (-not (Test-Path $Src)) {
        Write-Err2 "源文件不存在：$Src"
        exit 1
    }
    $dstDir = Split-Path -Parent $Dst
    if ($PSCmdlet.ShouldProcess($DstDir, "创建目录")) {
        New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    }
    Backup-IfExists -Path $Dst
    Write-Info "安装：$Dst"
    if ($PSCmdlet.ShouldProcess($Src, "复制到 $Dst")) {
        Copy-Item -Path $Src -Destination $Dst -Force
    }
}

# 复制整个目录（先备份再覆盖）
function Install-Dir {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string]$Src, [string]$Dst)
    if (-not (Test-Path $Src)) {
        Write-Err2 "源目录不存在：$Src"
        exit 1
    }
    if ($PSCmdlet.ShouldProcess($Dst, "创建目录")) {
        New-Item -ItemType Directory -Force -Path $Dst | Out-Null
    }
    Backup-IfExists -Path $Dst
    Write-Info "安装目录：$Dst"
    if ($PSCmdlet.ShouldProcess($Src, "递归复制到 $Dst")) {
        # 目标已存在则需重建（备份已把旧的移走，但保留空目录占位时使用）
        if (Test-Path $Dst) { Remove-Item -Path $Dst -Recurse -Force }
        Copy-Item -Path $Src -Destination $Dst -Recurse -Force
    }
}

# 主流程
Write-Host "Claude Code 全局配置安装器"
Write-Host "  源目录：$ScriptDir"
Write-Host "  目标目录：$TargetDir"
if ($WhatIfPreference) { Write-Host "  模式：干跑（-WhatIf，不实际修改文件）" }
Write-Host

# 前置检查
if (-not (Test-Path (Join-Path $ScriptDir 'CLAUDE.md'))) {
    Write-Err2 "源目录缺少 CLAUDE.md，请确认脚本与 CLAUDE.md 同目录"
    exit 1
}
if (-not (Test-Path (Join-Path $ScriptDir 'rules'))) {
    Write-Err2 "源目录缺少 rules/，请确认脚本与 rules/ 同目录"
    exit 1
}

# 创建目标根目录
if ($PSCmdlet.ShouldProcess($TargetDir, "创建目录")) {
    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
}

# 安装 CLAUDE.md
Install-File -Src (Join-Path $ScriptDir 'CLAUDE.md') -Dst (Join-Path $TargetDir 'CLAUDE.md')

# 安装 rules 目录
Install-Dir -Src (Join-Path $ScriptDir 'rules') -Dst (Join-Path $TargetDir 'rules')

Write-Host
Write-Info "安装完成"
Write-Host
Write-Host "后续步骤："
Write-Host "  1. 重启 Claude Code"
Write-Host "  2. 在任意 C# 项目中提问验证，例如："
Write-Host "       告诉我本项目的代码注释规范有哪些禁止项？"
Write-Host "     如果 Claude 能答出「禁止版本号、装饰符号、元信息」等内容，说明已生效"
Write-Host
if ($WhatIfPreference) {
    Write-Warn2 "本次为干跑模式（-WhatIf），未实际修改任何文件"
}

# 阻塞等待回车：仅在交互式终端且非 -WhatIf 时
# 双击 .ps1 时让用户看到结果再关窗；管道/重定向/计划任务场景不阻塞
if (-not $WhatIfPreference -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    Write-Host
    try {
        [void][Console]::In.ReadLine()
    } catch {
        # Ctrl+C 等异常吞掉即可
    }
}