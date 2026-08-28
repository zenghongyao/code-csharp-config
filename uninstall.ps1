# 一键卸载 Claude Code 全局配置（Windows PowerShell）
# 默认行为：从最近一次备份恢复（如果存在），并删除本次安装写入的文件
# 用法：
#   .\uninstall.ps1                回滚到上次备份（无备份则删除）
#   .\uninstall.ps1 -Purge         完全删除所有相关文件（含所有备份）
#   .\uninstall.ps1 -WhatIf        预览操作，不实际执行
#   .\uninstall.ps1 -Help          查看帮助

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Purge
)

$ErrorActionPreference = 'Stop'

$TargetDir = Join-Path $env:USERPROFILE '.claude'

# 颜色（仅当输出到终端时启用）
function Write-Info  { param($m) if ($Host.UI.SupportsVirtualTerminal) { Write-Host "[OK] $m" -ForegroundColor Green } else { Write-Host "[OK] $m" } }
function Write-Warn2 { param($m) if ($Host.UI.SupportsVirtualTerminal) { Write-Host "[WARN] $m" -ForegroundColor Yellow } else { Write-Host "[WARN] $m" } }
function Write-Err2  { param($m) if ($Host.UI.SupportsVirtualTerminal) { Write-Host "[ERROR] $m" -ForegroundColor Red } else { Write-Host "[ERROR] $m" } }

function Show-Help {
    @'
用法：.\uninstall.ps1 [选项]

选项：
  -Purge      完全删除所有相关文件，包括所有 .bak.<时间戳> 备份
  -WhatIf     预览将要执行的操作，不实际修改文件
  -Help       显示本帮助

默认行为：
  - 找到最近一次备份，恢复到 %USERPROFILE%\.claude\
  - 如果无备份（首次安装），直接删除目标文件/目录
  - 删除本次安装写入的内容：CLAUDE.md、rules/ 及其备份
'@
}

function Remove-Path {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param($Path)
    if (Test-Path $Path) {
        Write-Info "删除：$Path"
        if ($PSCmdlet.ShouldProcess($Path, "删除")) {
            Remove-Item -Path $Path -Recurse -Force
        }
    }
}

# 恢复最新备份：找到 <path>.bak.* 中时间戳最大的那个，重命名为 <path>
# 返回 $true 表示恢复了，$false 表示没找到备份
function Restore-LatestBackup {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param($TargetPath)
    $pattern = "$TargetPath.bak.*"
    if (-not (Test-Path $pattern)) { return $false }
    $latest = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        Select-Object -First 1
    if ($null -ne $latest) {
        Write-Info "恢复备份：$($latest.FullName) -> $TargetPath"
        if (Test-Path $TargetPath) {
            if ($PSCmdlet.ShouldProcess($TargetPath, "删除现有")) {
                Remove-Item -Path $TargetPath -Recurse -Force
            }
        }
        if ($PSCmdlet.ShouldProcess($latest.FullName, "重命名为 $TargetPath")) {
            Rename-Item -Path $latest.FullName -NewName (Split-Path -Leaf $TargetPath) -Force
        }
        return $true
    }
    return $false
}

# 删除所有 .bak.<时间戳> 备份（仅 -Purge 模式调用）
function Remove-AllBackups {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param($Pattern)
    if (Test-Path $Pattern) {
        Get-ChildItem -Path $Pattern -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Info "清理备份：$($_.FullName)"
            if ($PSCmdlet.ShouldProcess($_.FullName, "删除")) {
                Remove-Item -Path $_.FullName -Recurse -Force
            }
        }
    }
}

# 主流程
Write-Host "Claude Code 全局配置卸载器"
Write-Host "  目标目录：$TargetDir"
if ($WhatIfPreference) { Write-Host "  模式：干跑（-WhatIf）" }
if ($Purge) { Write-Host "  模式：完全删除（含所有备份）" }
Write-Host

if (-not (Test-Path $TargetDir)) {
    Write-Warn2 "目标目录不存在：$TargetDir，无需卸载"
    exit 0
}

if ($Purge) {
    # 完全删除：清掉当前文件 + 所有备份
    Remove-Path "$TargetDir\CLAUDE.md"
    Remove-Path "$TargetDir\rules"
    Remove-AllBackups "$TargetDir\CLAUDE.md.bak.*"
    Remove-AllBackups "$TargetDir\rules.bak.*"
    # rules 目录下递归清理
    if (Test-Path "$TargetDir\rules") {
        Get-ChildItem -Path "$TargetDir\rules" -Filter '*.bak.*' -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($_.FullName, "删除")) {
                Remove-Item -Path $_.FullName -Recurse -Force
            }
        }
    }
    # 若整个 .claude 目录为空，可顺手删除
    if ((Get-ChildItem -Path $TargetDir -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
        Remove-Path $TargetDir
    }
}
else {
    # 默认：尝试从最新备份恢复；无备份时（首次安装）直接删除本次内容
    if (-not (Restore-LatestBackup "$TargetDir\CLAUDE.md")) {
        Remove-Path "$TargetDir\CLAUDE.md"
    }

    # rules 是目录：恢复失败则删除目录（首次安装），恢复成功则保留
    if (Test-Path "$TargetDir\rules") {
        if (-not (Restore-LatestBackup "$TargetDir\rules")) {
            Remove-Path "$TargetDir\rules"
        }
        # 清理 rules 内部各文件的 .bak.*
        Get-ChildItem -Path "$TargetDir\rules" -Filter '*.bak.*' -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Info "清理文件级备份：$($_.FullName)"
            if ($PSCmdlet.ShouldProcess($_.FullName, "删除")) {
                Remove-Item -Path $_.FullName -Recurse -Force
            }
        }
    }

    # 顺带清理目录级的 .bak.*
    Remove-AllBackups "$TargetDir\rules.bak.*"
    Remove-AllBackups "$TargetDir\CLAUDE.md.bak.*"

    # 若整个 .claude 目录为空，可顺手删除
    if ((Get-ChildItem -Path $TargetDir -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
        Remove-Path $TargetDir
    }
}

Write-Host
Write-Info "卸载完成"
if ($WhatIfPreference) {
    Write-Warn2 "本次为干跑模式（-WhatIf），未实际修改任何文件"
}

# 阻塞等待回车：仅在交互式终端且非 -WhatIf 时
if (-not $WhatIfPreference -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    Write-Host
    try {
        [void][Console]::In.ReadLine()
    } catch {
        # Ctrl+C 等异常吞掉即可
    }
}