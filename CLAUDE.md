# CLAUDE.md — 全局用户级规范（C# / .NET）

对所有项目生效。项目级 `.claude/CLAUDE.md` 加载时合并，冲突以本文件为准。

---

## 0. 个人偏好
- 使用中文回复，代码注释使用中文
- 偏好简洁直接的代码风格，不写废话注释
- 先理解再动手，大规模改动前先列计划确认- 回答时先给出结论/方案概要，再展开细节。
- 修改代码前先说明将要改什么、为什么改；改动后给出差异说明。
- 不确定的地方明确指出"需要确认"，不要臆造。

## 1. 安全底线（所有项目通用）
- 永远不在代码中硬编码真实 API 密钥 / 连接字符串 / 密码
- 执行 `rm -rf`、`DROP TABLE`、`git push --force` 等危险命令前必须确认
- 不强制推送到 main/master 分支
- 不要删除任何函数或类，即使你认为没有被调用——可能有动态引用或插件加载
- 不要直接修改数据库表结构（增删列/改类型），必须生成迁移脚本并确认

## 2. 通用工程原则

### 2.1 必须复用，禁止重复造轮子

项目内的工具类、常量、通用组件是团队隐性资产。重复实现会导致代码风格不一致、维护成本翻倍、新人上手成本增加。

**DO**：

- 新写功能前，先 `grep` / 搜索项目是否已有类似工具类、常量、辅助方法
- 优先使用项目已有的 `Utils/`、`Common/`、`Helpers/`、`Extensions/`、`Constants/` 命名空间下的内容
- 看 NuGet 依赖是否已提供现成能力（如 JSON、日期、正则、加密、CSV、HTTP 客户端等）
- 已有但功能不完整时，**优先扩展现有**而不是新建并行的同类组件

**DON'T**：

- 日期 / 字符串格式化满地散写，不抽公共方法
- 自己写 MD5 / SHA / Base64 加解密，而项目已有 `CryptoHelper`
- 每个 Service 各自定义 `IsNullOrEmpty`、`TrimToNull` 等扩展方法
- 重复定义状态码、错误码、字典项枚举常量
- 重复封装 HTTP 客户端、数据库连接、配置读取等基础设施

**WHEN** 准备写的功能在项目里可能已有：
**DO** `grep` / 搜索确认 → 优先调用现有 → 不满足则扩展现有 → 实在不行才新建，并在文件头注释中说明为何不能复用现有

例外（可新建）：项目内确实无此能力 / 与现有组件有明显行为差异 / NuGet 现成依赖也不满足；无论哪种，新建时必须在注释中说明为何不复用。

## 3. C# 编码通用约定

### 3.1 命名
- 类 / 接口 / 方法 / 属性 / 枚举：PascalCase（接口以 `I` 开头）
- 局部变量 / 参数 / 字段：camelCase（私有实例字段加 `_` 前缀，静态字段加 `s_`）
- 常量：PascalCase（不用全大写）
- 异步方法以 `Async` 结尾

### 3.2 异步
- 优先使用 async/await，禁止 `.Result`、`.Wait()`、`.GetAwaiter().GetResult()`
- 禁止 `async void`（除事件处理器外）
- 取消令牌透传到底层 IO 调用
- `ConfigureAwait(false)` 仅在库代码中使用，应用层代码省略

### 3.3 资源与异常
- 可释放对象用 `using` 声明 / 语句
- 不要吞异常（空 catch 块），至少要记录日志
- 参数校验放方法开头，用 `ArgumentNullException.ThrowIfNull`

### 3.4 可空与类型安全
- 启用可空引用类型（`<Nullable>enable</Nullable>`）
- 避免 `as` + null 检查的模式，优先用模式匹配 `is T x`
- 强制转换前先判断，不假设类型

## 4. 代码注释规范（核心原则）

详细规则：`@~/.claude/rules/csharp-comment-standards.md`

### 4.1 禁止出现在注释中的内容
- ❌ 版本号 / 补丁号（`v9.4`、`V1.0`、`方案A/B/C`）
- ❌ 装饰符号（`★▶◀◆●■✓✗→←↑↓`、`=====`、`-----` 等分隔符）
- ❌ 元信息（git hash、完整 branch 名、PR/issue 编号、时间戳、作者姓名）
- ❌ "修订 / 新增 / 修改 / 撤销"等带版本前后缀的措辞

### 4.2 允许 ✅
- 技术性说明（如 `// C# 7.3 兼容：避免 switch expression`）
- 业务原因说明（为什么这么写、踩过什么坑）
- 正常的 XML doc comment（summary / param / returns / remarks）

## 5. Git 提交规范（核心原则）

详细规则：`@~/.claude/rules/git-commit-standards.md`

### 5.1 格式
```
<type>: <description>

[body]
```
- type 见 5.2，description 用中文动词开头，≤ 70 字，不加句号
- 不用 `type(scope):` 括号写法，信息合并到 description
- 正文结构：改了什么 → 为什么改 → 影响范围

### 5.2 type 列表
| type | 含义 | 推荐动词 |
|------|------|---------|
| `feat` | 新功能 | 新增 / 引入 / 接入 |
| `fix` | 修复 bug | 修复 / 修正 |
| `refactor` | 重构 | 重构 / 抽取 / 拆分 |
| `perf` | 性能优化 | 优化 |
| `style` | 代码格式 | 格式化 / 统一 |
| `docs` | 文档 | 同步 / 更新 / 补充 |
| `test` | 测试 | 新增测试 / 补充测试 |
| `chore` | 构建/工具/配置 | 调整 / 升级 |
| `deps` | 依赖更新 | 升级 / 更新 |
| `revert` | 撤销提交 | 撤销 |
| `version` | 版本号更新 | 升级到 |
| `merge` | 合并分支 | 合并 |
| `wip` | 工作进行中 | 开始开发 |
| `conflict` | 解决合并冲突 | 解决 |

### 5.3 commit message 禁止出现
- ❌ 版本号 / 方案标识（`v9.x`、`方案A`、`补丁`）
- ❌ 装饰符号（同 4.1）
- ❌ 元信息（git hash、branch 名、日期、作者）
- ❌ AI 痕迹关键词：`claude`、`agent`、`AI 生成`、`任务清单`、`上下文`、`prompt`、`指令`、`项目记忆`、`memory`、`本会话`

## 6. 触发式规则（看到 → 直接做）

### 6.1 SDK 10 Git 构建错误
**WHEN** 看到以下构建错误：
```
Microsoft.Build.Tasks.Git.targets(25,5): error :
读取 GIT 存储库信息时出错: 分析文件".git/config"中的配置行 1 时出错:
意外的字符 U+fffd
```
**DO** 直接在项目根 `Directory.Build.props` 加：
```xml
<Project>
  <PropertyGroup>
    <EnableSourceControlManagerQueries>false</EnableSourceControlManagerQueries>
    <EmbedUntrackedSources>false</EmbedUntrackedSources>
    <DeterministicSourcePaths>false</DeterministicSourcePaths>
  </PropertyGroup>
</Project>
```
**注意**：必须用属性开关（props 阶段），不能用目标覆盖；仅设 `EnableSourceLink=false` 不够。
**根因**：SDK 10 默认开启 SourceLink → 强制查询 Git → 部分 Windows 环境下 LocateRepository 任务失败。
**不要做**：不要去改 .git 内容、不要改编码、不要归因于中文路径——这些都是症状不是原因。

## 7. 共同原则
1. **Git blame 干净**——注释和 commit 不绑版本号，便于追溯
2. **历史档案原则**——commit message 与代码注释同等重要
3. **风格统一**——一个仓库一套规范，跨代码 / 提交保持一致
4. **自动化友好**——规范便于脚本 lint 检查
