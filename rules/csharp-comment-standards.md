# C# 代码注释详细规范

本文件是全局 CLAUDE.md 第 4 节的扩展。引用方式：`@~/.claude/rules/csharp-comment-standards.md`

---

## 1. 禁止内容清单

### 1.1 版本号 / 方案标识

- ❌ `v9.x`（如 `v9.4`、`v9.5`、`v9.5.1`）
- ❌ `V1.0`、`V2.0` 等任何 `V` + 数字 + 小数点格式
- ❌ `方案A`、`方案B`、`方案C` 等方案标识
- ❌ `v9.1`、`v9.2`、`v9.3` 等具体补丁号单独出现在注释中
- ❌ 中文"修订"、"新增"、"修改"、"撤销"等带版本前后缀的措辞
  - 反例：`v9.4 新增：xxx`、`v9.5 修订：xxx`、`v9.5.1 修订：xxx`

### 1.2 特殊符号（注释中）

- ❌ `★`（黑色五角星）
- ❌ `▶◀◆●■` 等装饰性符号
- ❌ `✓`、`✗`、`✔`、`✘` 等勾叉符号
- ❌ `→`、`←`、`↑`、`↓`（业务/技术说明中可使用，但不应作为注释开头标记）
- ❌ `>>>>>`、`=====`、`-----` 等分隔符

### 1.3 元信息

- ❌ 提交 hash（git commit id）
- ❌ 完整 branch 名（如 `hyz_feat_迁移优化`）
- ❌ PR 编号、issue 编号
- ❌ 时间戳（如 `2026-08-18`）
- ❌ 作者姓名

---

## 2. 正确示例 ✅

```csharp
/// <summary>
/// 频率模式枚举
/// </summary>
public enum FrequencyMode { ... }

/// <summary>
/// 判断指定 TransferType 是否启用（用于异常检测按需加载）
/// </summary>
private static bool IsTransferTypeEnabled(...) { ... }

// 允许：C# 语言版本说明（技术注释）
// C# 7.3 兼容：避免 switch expression，改用 if-else
public FrequencyMode GetFrequencyModeForSubModule(string name)
{
    if (name == "WaterCommon") return MediumFrequency;
    if (name == "SensorCommon") return HighFrequency;
    // ...
}
```

---

## 3. 错误示例 ❌

```csharp
/// <summary>
/// 频率模式枚举（v9.4 新增）
/// </summary>

// v9.4 校验：WatermeterID 子模块必须显式指定 FrequencyMode

// ★ 异常检测服务注册（3 个子模块）
RegisterService(...);
```
