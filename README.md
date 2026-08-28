# Claude Code 全局配置（C# / .NET）

优化后的全局 CLAUDE.md 配置包，适用于 C# / .NET 开发者。

---

## 文件结构

```text
claude-global-config/
├── CLAUDE.md                          # 主文件（~120 行，核心规则）
├── install.bat                        # Windows 安装启动器（双击即用）
├── install.ps1                        # Windows 安装脚本（命令行调用）
├── install.sh                         # macOS / Linux 安装脚本
├── uninstall.bat                      # Windows 卸载启动器（双击即用）
├── uninstall.ps1                      # Windows 卸载脚本（命令行调用）
├── uninstall.sh                       # macOS / Linux 卸载脚本
├── rules/
│   ├── csharp-comment-standards.md    # C# 注释详细规范（主文件第 4 节扩展）
│   └── git-commit-standards.md        # Git 提交详细规范（主文件第 5 节扩展）
└── README.md                          # 本文件
```

---

## 安装步骤

### 推荐：一键脚本

脚本会自动定位源目录（脚本所在目录）、创建目标目录、对已存在的旧文件**自动备份**为 `*.bak.<时间戳>`，并保留最近 3 个备份。

### Windows

**推荐：双击 `install.bat`**

直接在资源管理器里双击 `install.bat` 即可。它会：

- 用 `-ExecutionPolicy Bypass` 绕过 PowerShell 执行策略（不需要先 `Set-ExecutionPolicy`）
- 自动定位脚本所在目录，不依赖当前工作目录
- 末尾 `pause` 留窗，让你看清输出结果再关

命令行附加参数同理：`install.bat -WhatIf` 预览，`install.bat -Purge` 配套卸载。

**备选：直接调 `install.ps1`**

适合已设过 `Set-ExecutionPolicy RemoteSigned` 的用户：

```powershell
# 进入解压后的目录
cd claude-global-config

.\install.ps1 -WhatIf    # 预览
.\install.ps1            # 实际安装
```

### macOS / Linux

```bash
# 进入解压后的目录
cd claude-global-config

# 安装（先看预览再加 --dry-run 去掉即可实际执行）
./install.sh --dry-run    # 预览
./install.sh              # 实际安装
```

### 备选：手动复制

如果不想用脚本，一行命令也能装：

**Windows（PowerShell）**：

```powershell
Copy-Item claude-global-config\CLAUDE.md "$env:USERPROFILE\.claude\CLAUDE.md" -Force
Copy-Item claude-global-config\rules "$env:USERPROFILE\.claude\rules" -Recurse -Force
```

**macOS / Linux**：

```bash
mkdir -p ~/.claude && cp -r claude-global-config/CLAUDE.md claude-global-config/rules ~/.claude/
```

### 脚本通用参数

| 平台 | 干跑模式 | 用途 |
| ---- | --------- | ---- |
| Windows | `-WhatIf` | 预览将要执行的操作，不实际修改文件 |
| macOS / Linux | `--dry-run` | 同上 |

干跑会打印每一步要执行的命令，确认无误后再去掉参数跑一次正式安装。

---

## 卸载步骤

脚本默认从最近一次备份**回滚**到上次安装前的状态；如果没有备份（即首次安装），则直接删除当前文件。

### Windows 卸载

**推荐：双击 `uninstall.bat`**（用法与安装一致，`uninstall.bat -Purge` 完全清除）。

**备选：直接调 `uninstall.ps1`**

```powershell
.\uninstall.ps1 -WhatIf    # 预览
.\uninstall.ps1            # 实际卸载
```

### macOS / Linux 卸载

```bash
./uninstall.sh --dry-run    # 预览
./uninstall.sh              # 实际卸载
```

完全清除（包括所有 `*.bak.<时间戳>` 备份）：

- Windows：加 `-Purge`
- macOS / Linux：加 `--purge`

如果之前是用手动命令安装的，找一下 `~/.claude/CLAUDE.md.bak.*` 之类的备份手动恢复即可；没有备份就直接删除 `~/.claude/CLAUDE.md` 和 `~/.claude/rules`。

---

## 设计说明

### 为什么拆成主文件 + rules 目录？

1. **注意力配额**：前沿 LLM 可靠执行的指令约 150–200 条，系统提示已占约 50 条，留给用户配置的空间有限
2. **主文件精简**：核心规则控制在 ~120 行，确保高遵从率
3. **详情按需加载**：详细示例和补充说明通过 `@~/.claude/rules/xxx.md` 引用，仅在需要时读取
4. **触发式规则**：SDK 10 构建错误等场景用 `WHEN...DO...` 模式，模型命中率更高

### 与原版相比的改进

| 维度 | 原版 | 优化后 |
| ---- | ---- | -------- |
| 主文件行数 | ~250 行 | ~120 行 |
| C# 语言规范 | 无 | 命名 / 异步 / 资源 / 可空 4 大类 |
| 注释规范 | 5 节详细展开 | 核心 2 节 + @ 引用详情 |
| Git 规范 | 10 节 + 重复 | 核心 3 节 + @ 引用详情 |
| SDK 10 问题 | 5 节长篇大论 | 1 节触发式 |
| 冗余内容 | 重复章节、内部记忆细节 | 已清理 |

---

## 验证是否生效

重启 Claude Code 后，在任意 C# 项目中提问：

```text
告诉我本项目的代码注释规范有哪些禁止项？
```

如果 Claude 能回答出"禁止版本号、装饰符号、元信息"等内容，说明全局配置已加载。

---

## 项目级配置建议

每个项目根目录可以放一份 `CLAUDE.md`，写入项目专属信息：

- 技术栈版本（.NET 版本、ORM、前端框架等）
- 项目架构（分层结构、目录约定）
- 常用命令（build / test / run / migration）
- 项目特有的编码约定

项目级配置会与全局配置合并，冲突时**以全局为准**（本规范已在全局文件中声明）。
