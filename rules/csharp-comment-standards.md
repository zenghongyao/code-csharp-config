# C# 代码注释详细规范

本文件是 Claude 与 Codex 共享的 C# 注释规范。由各自的全局入口文件要求在编写或修改 C# 代码前读取。

## XML 文档注释强制要求

### 适用范围

- 新增或修改 C# 类型及成员时，必须添加或同步更新中文 XML 文档注释，使用 `///` 写在对应声明上方，不能以普通注释替代。
- 覆盖类、接口、结构体、记录类型、枚举及枚举成员、构造函数、方法、属性、索引器、字段、常量、事件和委托等适用声明。
- 适用于所有访问级别，不因成员为私有、实现简单或属于自动属性而省略。
- 修改已有成员时，补齐缺失注释并更新过时描述；未涉及的历史代码不要求全量补齐。
- 自动生成代码和第三方代码不直接修改；局部变量及 Lambda 表达式按需使用普通注释。

### 标签与内容

- 每个类型及成员必须包含有实际含义的 `<summary>`，说明用途或行为，禁止空注释、占位文字和仅重复名称。
- 有参数时必须逐一编写 `<param>`，有泛型参数时必须逐一编写 `<typeparam>`，标签中的参数名必须与声明一致。
- 有返回值的方法必须编写 `<returns>`；返回 `Task`、`ValueTask` 等任务类型的异步方法应说明任务完成的含义，返回 `Task<T>`、`ValueTask<T>` 时还应说明完成后的结果；`void` 方法和构造函数不写 `<returns>`。
- 属性在 `<summary>` 中说明含义；取值范围、单位、默认值或空值语义影响使用时，使用 `<value>` 或 `<remarks>` 补充说明。
- 对明确的异常条件使用 `<exception>`，对必要的使用约束、边界条件和副作用使用 `<remarks>`，内容必须与实现一致，不臆造异常或行为。
- 参数、返回值或行为变化时同步更新相关标签，保持 XML 结构完整，并遵守下文关于中文注释、文本末尾及禁止内容的规定。

## 禁止内容

### 版本号与方案标识

- 不在注释中写 v9.x、V1.0 等版本号或补丁号。
- 不写方案A、方案B、方案C 等方案标识。
- 不写修订、新增、修改、撤销等带版本前后缀的措辞。

### 装饰符号

- 不使用 ★、▶、◀、◆、●、■、✓、✗、✔、✘ 等装饰性符号。
- 业务或技术说明可以表达方向，但不以 →、←、↑、↓ 作为注释开头标记。
- 不使用 >>>>>、=====、----- 等分隔符。

### 注释末尾

- 每条注释文本的末尾不添加句号、逗号、分号、冒号、感叹号、问号、省略号、顿号及其他中文或英文标点。
- 末尾不添加装饰符号、分隔符或表情符号。
- XML 文档注释中的 summary、param、returns、remarks 等文本末尾同样不添加句号、逗号、分号、冒号、感叹号、问号、省略号、顿号及其他中文或英文标点、装饰符或表情。
- XML 文档注释中的标签和代码语法本身不受此限制，例如 </summary>。

### 元信息

- 不写提交 hash、完整 branch 名、PR 或 issue 编号、时间戳和作者姓名。

## 允许内容

- 符合上述强制要求的 XML 文档注释，例如 summary、param、typeparam、returns、value、exception、remarks。
- 解释业务原因、约束条件和已知陷阱。
- 必要的技术兼容性说明，例如 C# 7.3 兼容时避免 switch expression。

## 示例

枚举及枚举成员：

~~~csharp
/// <summary>
/// 频率模式枚举
/// </summary>
public enum FrequencyMode
{
    /// <summary>
    /// 按固定频率执行
    /// </summary>
    Fixed,

    /// <summary>
    /// 按需执行
    /// </summary>
    OnDemand
}
~~~

类型、属性及方法：

~~~csharp
using System;

/// <summary>
/// 订单明细
/// </summary>
public sealed class OrderItem
{
    /// <summary>
    /// 订单明细中的商品数量
    /// </summary>
    public int Quantity { get; set; }

    /// <summary>
    /// 判断商品数量是否达到指定的最小数量
    /// </summary>
    /// <param name="minimumQuantity">要求的最小数量，必须大于或等于零</param>
    /// <returns>商品数量达到最小数量时返回 true，否则返回 false</returns>
    /// <exception cref="ArgumentOutOfRangeException">最小数量小于零</exception>
    public bool MeetsMinimumQuantity(int minimumQuantity)
    {
        if (minimumQuantity < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(minimumQuantity), "最小数量不能小于零");
        }

        return Quantity >= minimumQuantity;
    }
}
~~~

不要把版本记录、方案名称或装饰性标记写进以上注释。
