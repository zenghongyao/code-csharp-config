# Claude Code 全局配置（C# / .NET）

优化后的全局 CLAUDE.md 配置包，适用于 C# / .NET 开发者。

---

## 文件结构

```
claude-global-config/
├── CLAUDE.md                          # 主文件（~120 行，核心规则）
├── rules/
│   ├── csharp-comment-standards.md    # C# 注释详细规范（主文件第 3 节扩展）
│   └── git-commit-standards.md        # Git 提交详细规范（主文件第 4 节扩展）
└── README.md                          # 本文件
```

---

## 安装步骤

### Windows (PowerShell)

```powershell
# 1. 解压到临时目录
Expand-Archive claude-global-config.zip -DestinationPath .

# 2. 创建 .claude 目录（如不存在）
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\rules"

# 3. 复制主文件
Copy-Item claude-global-config\CLAUDE.md "$env:USERPROFILE\.claude\CLAUDE.md"

# 4. 复制 rules 目录
Copy-Item claude-global-config\rules\* "$env:USERPROFILE\.claude\rules\" -Recurse
```

### macOS / Linux

```bash
# 1. 解压
unzip claude-global-config.zip

# 2. 创建目录
mkdir -p ~/.claude/rules

# 3. 复制文件
cp claude-global-config/CLAUDE.md ~/.claude/CLAUDE.md
cp claude-global-config/rules/* ~/.claude/rules/
```

---

## 设计说明

### 为什么拆成主文件 + rules 目录？

1. **注意力配额**：前沿 LLM 可靠执行的指令约 150–200 条，系统提示已占约 50 条，留给用户配置的空间有限
2. **主文件精简**：核心规则控制在 ~120 行，确保高遵从率
3. **详情按需加载**：详细示例和补充说明通过 `@~/.claude/rules/xxx.md` 引用，仅在需要时读取
4. **触发式规则**：SDK 10 构建错误等场景用 `WHEN...DO...` 模式，模型命中率更高

### 与原版相比的改进

| 维度 | 原版 | 优化后 |
|------|------|--------|
| 主文件行数 | ~250 行 | ~120 行 |
| C# 语言规范 | 无 | 命名 / 异步 / 资源 / 可空 4 大类 |
| 注释规范 | 5 节详细展开 | 核心 2 节 + @ 引用详情 |
| Git 规范 | 10 节 + 重复 | 核心 3 节 + @ 引用详情 |
| SDK 10 问题 | 5 节长篇大论 | 1 节触发式 |
| 冗余内容 | 重复章节、内部记忆细节 | 已清理 |

---

## 验证是否生效

重启 Claude Code 后，在任意 C# 项目中提问：

```
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
