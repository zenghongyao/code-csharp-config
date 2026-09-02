# Claude 与 Codex 全局规则包（C# / .NET）

一个仓库同时维护 Claude Code 与 Codex 的全局 C#/.NET 开发规则。两种工具使用各自的入口文件，共享同一套注释和 Git 提交细则。

## 文件结构

~~~text
claude-global-config/
├── CLAUDE.md                         # Claude Code 全局入口
├── AGENTS.md                         # Codex 全局入口
├── rules/
│   ├── csharp-comment-standards.md   # 共享的 C# 注释细则
│   └── git-commit-standards.md       # 共享的 Git 提交细则
├── install.ps1 / install.sh          # 统一安装器
├── uninstall.ps1 / uninstall.sh      # 统一卸载器
└── install.bat / uninstall.bat       # Windows 双击启动器
~~~

## 安装位置

| 目标 | 入口文件 | 详细规则目录 |
| --- | --- | --- |
| Claude | ~/.claude/CLAUDE.md | ~/.claude/rules/ |
| Codex | ~/.codex/AGENTS.md | ~/.codex/rules/ |

安装时会分别备份已有入口和非空 rules 目录为 .bak.时间戳，并保留最近 3 份备份。

## 安装

未指定目标时，双击 Windows 启动器或在交互式终端运行脚本，会要求选择 Claude、Codex 或两者。自动化、重定向或管道环境必须显式指定目标。

### Windows

推荐双击 install.bat，然后根据提示选择目标。

也可以在 PowerShell 中执行：

~~~powershell
.\install.ps1 -Target Claude -WhatIf
.\install.ps1 -Target Codex
.\install.ps1 -Target All
~~~

install.bat 会原样转发参数，例如：

~~~text
install.bat -Target All -WhatIf
~~~

### macOS / Linux

~~~bash
bash install.sh --target claude --dry-run
bash install.sh --target codex
bash install.sh --target all
~~~

## 卸载与回滚

默认卸载会恢复所选目标最近一次备份；如果没有备份，则删除本包安装的入口和 rules 目录。

### Windows

~~~powershell
.\uninstall.ps1 -Target Claude -WhatIf
.\uninstall.ps1 -Target Codex
.\uninstall.ps1 -Target All
~~~

双击 uninstall.bat 也会交互选择目标，并可转发参数：

~~~text
uninstall.bat -Target All -Purge
~~~

### macOS / Linux

~~~bash
bash uninstall.sh --target claude --dry-run
bash uninstall.sh --target codex
bash uninstall.sh --target all
~~~

使用完全清除选项时，不恢复旧配置，并删除所选目标中本包入口、rules 目录及其备份：

~~~powershell
.\uninstall.ps1 -Target Codex -Purge
~~~

~~~bash
bash uninstall.sh --target codex --purge
~~~

## 参数参考

| 平台 | 安装目标 | 干跑 | 完全清除 |
| --- | --- | --- | --- |
| PowerShell | -Target Claude、Codex 或 All | -WhatIf | -Purge（仅卸载） |
| macOS / Linux | --target claude、codex 或 all | --dry-run | --purge（仅卸载） |

PowerShell 脚本支持 -Help，Shell 脚本支持 --help。

## 规则设计

- Claude 使用 CLAUDE.md，Codex 使用 AGENTS.md；两者均包含相同的核心安全、复用和 C# 编码约定。
- 编写 C# 注释或准备 Git 提交信息时，各入口会指向安装在本工具目录下的共享详细规则。
- 项目级规则可以补充或覆盖通用约定，但安全要求始终保留。
- 规则不再使用 Claude 专属的按需加载语法，因此可以由两个工具以各自的入口机制使用。

安装完成后重启相应工具。在任意 C# 项目中询问代码注释禁止项或 Git 提交格式，即可验证规则是否被加载。
