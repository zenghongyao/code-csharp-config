# C# / .NET 全局开发规范

适用于所有项目。项目级 CLAUDE.md 可以补充或覆盖通用约定；安全要求始终保留。

## 个人偏好

- 使用中文回复，代码注释使用中文。
- 编写 Markdown 文档时始终使用中文。
- 先理解再动手；大规模改动前先给出计划并确认。
- 回答先给出结论或方案概要，再展开细节。
- 修改前说明改什么和原因；完成后说明实际差异。
- 不确定时明确说明需要确认，不臆造。

## 安全底线

- 不在代码中硬编码真实 API 密钥、连接字符串或密码。
- 执行删除数据、删除文件、DROP TABLE、git push --force 等危险操作前必须确认。
- 不强制推送到 main 或 master。
- 删除函数或类前先搜索引用并评估影响；无法确认影响时先询问。
- 数据库结构变更应生成迁移脚本；执行迁移前必须确认。

## 工程原则

新增功能前先搜索项目中是否已有相近的工具类、常量、辅助方法或依赖能力。优先复用或扩展现有 Utils、Common、Helpers、Extensions、Constants 及已有依赖；确实无法复用时才新建，并说明原因。

不要重复实现日期、字符串、加密、HTTP、数据库连接、配置读取、状态码或错误码等通用能力。

## C# 编码约定

- 类、接口、方法、属性、枚举使用 PascalCase；接口以 I 开头。
- 局部变量、参数、字段使用 camelCase；私有实例字段以 _ 开头，静态字段以 s_ 开头。
- 常量使用 PascalCase；异步方法以 Async 结尾。
- 优先 async/await；除事件处理器外不使用 async void，不使用 .Result、.Wait() 或 .GetAwaiter().GetResult()。
- 将取消令牌透传到底层 IO 调用；ConfigureAwait(false) 仅用于库代码。
- 可释放对象使用 using；不吞异常，至少记录日志。
- 参数校验放在方法开头，优先使用 ArgumentNullException.ThrowIfNull。
- 启用可空引用类型；优先模式匹配而非 as 加 null 检查；强制转换前验证类型。

## 注释与提交

- 编写或修改 C# 注释前，读取 ~/.claude/rules/csharp-comment-standards.md。
- 准备 Git 提交信息前，读取 ~/.claude/rules/git-commit-standards.md。
- 注释和提交信息不包含版本号、装饰符号、提交元信息或 AI 协作痕迹。
- 代码注释文本末尾不添加中文或英文标点、分隔符或装饰字符；XML 标签和代码语法除外。

## SDK 10 Git 构建错误

当构建出现 Microsoft.Build.Tasks.Git.targets 的 Git 配置解析错误时，在项目根 Directory.Build.props 的 PropertyGroup 中加入：

~~~xml
<EnableSourceControlManagerQueries>false</EnableSourceControlManagerQueries>
<EmbedUntrackedSources>false</EmbedUntrackedSources>
<DeterministicSourcePaths>false</DeterministicSourcePaths>
~~~

使用属性开关，不修改 .git 内容，也不要用目标覆盖替代。

## 共同原则

保持 Git blame 干净、提交历史可读、代码风格统一，并让规则便于自动化检查。
