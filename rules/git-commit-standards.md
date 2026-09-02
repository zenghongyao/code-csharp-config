# Git 提交规范详细说明

本文件是 Claude 与 Codex 共享的 Git 提交规范。由各自的全局入口文件在准备提交信息时按需读取。

## 格式

~~~text
<type>: <description>

[body]

[footer]
~~~

- type 与 description 必填；description 用中文动词开头，描述做了什么及对象。
- description 不超过 70 字，不加句号；超出的细节放入 body。
- 不使用 type(scope) 形式；将 scope 信息写入 description。
- body 按改了什么、为什么改、怎么用和影响范围组织，按实际需要取舍。

## type 与推荐动词

| type | 含义 | 推荐中文动词 |
| ---- | ---- | ------------ |
| feat | 新功能 | 新增 / 引入 / 接入 |
| fix | 修复 bug | 修复 / 修正 |
| docs | 文档 | 同步 / 更新 / 补充 / 调整 |
| style | 代码格式 | 格式化 / 统一 |
| refactor | 重构 | 重构 / 抽取 / 拆分 |
| perf | 性能优化 | 优化 |
| test | 测试 | 新增测试 / 补充测试 |
| chore | 构建、工具或配置 | 调整 / 升级 |
| deps | 依赖更新 | 升级 / 更新 |
| revert | 撤销提交 | 撤销 |
| version | 版本号更新 | 升级到 |
| merge | 合并分支 | 合并 |
| wip | 临时工作 | 开始开发 |
| conflict | 解决合并冲突 | 解决 |

## 禁止内容

- 版本号、方案标识、补丁字样和装饰符号。
- Git hash、完整 branch 名、日期、作者姓名和过长文件路径。
- Claude、Codex、agent、AI 生成、prompt、上下文、任务清单、项目记忆等 AI 协作过程描述。

## 提交前检查

- type 在允许列表内，description 完整且不超过 70 字。
- 标题脱离项目背景仍能读懂，不含版本号、方案名或装饰符号。
- 正文在需要时说明改了什么、为什么改和影响范围。
- 不包含 Git 元信息或 AI 协作过程描述。
