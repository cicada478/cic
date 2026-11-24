# cic

**简体中文** | [English](inst/doc/README.en.md)

面向 R 与单细胞分析工作流的日常效率工具：安全保存结果、追踪输出文件、便捷录入和排序列表。

**本文档对应 v0.4.1。** 本次增加 `list_edit()`，保留 `out()`、`outputs()` 和 `ggsave1()`。列表编辑需要交互式 R，编辑期间占用当前 R 会话。

## 选择你的任务

| 我想做什么 | 函数 | 详细说明 |
|---|---|---|
| 保存 RDS、CSV 等结果时统一命名和防止覆盖 | `out()` | [安全保存分析结果](vignettes/safe-outputs.Rmd) |
| 查看输出路径和文件是否存在 | `outputs()` | [输出日志](vignettes/safe-outputs.Rmd) |
| 保存 ggplot 图形 | `ggsave1()` | [绘图保存](vignettes/safe-outputs.Rmd) |
| 输入、粘贴和排序 marker genes、颜色或细胞类型 | `list_edit()` | [创建基因集和细胞类型顺序](vignettes/list-editor.Rmd) |

## 安装与版本

已发布版本及下载文件以 [GitHub Releases](https://github.com/cicada478/cic/releases) 为准。以下说明对应v0.4.1；0.3.1 不包含 `list_edit()`。

从 Releases 下载所需版本的源码包，然后安装下载的文件。安装前重启已加载旧版 `cic` 的 R 会话：

```r
install.packages(c("data.table", "fs", "ggplot2"))
# 替换为实际下载位置
install.packages("path/to/cic_VERSION.tar.gz", repos = NULL, type = "source")
```

从本地源码安装：在包根目录运行以下代码，或安装本地构建的 `cic_0.4.1.tar.gz`。

```r
install.packages(c("data.table", "fs", "ggplot2"))
install.packages(".", repos = NULL, type = "source")
install.packages(c("shiny", "jsonlite")) # 仅列表编辑器需要
# install.packages("rstudioapi")        # 仅 RStudio dialog 模式需要
library(cic)
packageVersion("cic")
```

独立窗口使用已有的 Edge/Chrome，不需要安装 DataEditR。交互依赖是可选的，不影响输出工具。

## 三个快速示例

### 保存并追踪结果

```r
path <- cic::out("results/markers.csv")
write.csv(data.frame(gene = c("CD3D", "MS4A1")), path, row.names = FALSE)
cic::outputs("results")
```

`out()` 返回带当天日期的路径，创建父目录并处理重名；实际写文件的是 `write.csv()`。
日志中的 `exists` 显示文件现在是否存在。重复运行默认不会覆盖已有结果。

### 保存图形

```r
p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
cic::ggsave1("figures/scatter.pdf", p, width = 6, height = 4)
```

`ggsave1()` 复用 `out()` 的路径与日志规则。重名时，默认在交互会话中询问，在非交互运行中自动编号；`confirm = FALSE` 跳过确认并允许覆盖。

### 创建列表

```r
cell_order <- cic::list_edit() # 最终一列：字符向量；多列：命名 list
markers <- cic::list_edit(list(T_cell = c("CD3D", "CD3E")), output = "list")
```

输入或粘贴后按 `Enter` 向下、`Tab` 向右；拖动列内手柄排序，点击 **Done & return** 返回 R。
编辑期间占用当前 R 会话。完整操作说明见[列表教程](vignettes/list-editor.Rmd)。

## list_edit 的返回类型和窗口

| 参数 | 行为 |
|---|---|
| `output = "auto"`（默认） | 完成时一列返回字符向量，多列返回命名 list；空列也计数 |
| `output = "list"` | 始终返回命名 list，包括只有一列的情况 |
| `output = "vector"` | 只允许一列，返回字符向量；界面禁止增加列 |
| `viewer = "auto"`（默认） | Windows 优先使用已有 Edge/Chrome 独立窗口；找不到程序或其他平台时使用默认浏览器 |
| `viewer = "window"` | 同 auto；找不到支持的程序时显示提示并退回浏览器 |
| `viewer = "browser"` | 使用默认浏览器，可能打开为标签页 |
| `viewer = "dialog"` | 使用 RStudio 内置对话框；需要 rstudioapi，仍受其移动与缩放限制 |

独立窗口有桌面移动、缩放和最大化控件，但不是始终置顶窗口。

```r
genes <- cic::list_edit(output = "vector", viewer = "browser")
markers <- cic::list_edit(file = "markers.csv", output = "list")
# RStudio 内使用：
cell_order <- cic::list_edit(viewer = "dialog")
```

列名必须非空且唯一；空白单元格会被忽略，文本 `001`、重复值和顺序会保留。
单列向量不保留列标题；向量元素本身的 names 不保留。各列独立，不适合成对重排“细胞类型—颜色”关系。

### 文件导入

`file` 使用 `data.table::fread()` 自动识别 CSV、TSV、分号分隔等 UTF-8 文本（支持 BOM），首个非空行作为列名。所有列按字符读取，保留文本 `NA` 和非空值两侧空格。

包含分隔符或双引号的值需加引号，内部双引号写成两个双引号。解析警告会转为错误，不返回部分数据。Excel、RDS 等二进制格式不支持直接导入；导出仍为 CSV。示例及操作说明见[列表编辑教程](vignettes/list-editor.Rmd)。

## 文档与更新

- 完整参数帮助：`?cic::out`、`?cic::outputs`、`?cic::ggsave1`、`?cic::list_edit`。
- 教程：[安全保存分析结果](vignettes/safe-outputs.Rmd)、[创建列表](vignettes/list-editor.Rmd)，每篇均有英文部分。
- 版本变化见[更新记录](NEWS.md)、[English changelog](inst/doc/NEWS.en.md)及 [v0.4.1 发布说明](releases/v0.4.1.md)。
- 文档站采用 pkgdown；正式 Release 才部署稳定站，main/PR 只生成开发预览文件。
  目标地址为 `https://cicada478.github.io/cic/`，是否已上线以实际部署结果为准，详见[维护说明](DEVELOPMENT.md)。

## 使用限制与验证范围

输出日志记录路径分配，而不是保存成功；日志含本地绝对路径和可能的脚本名，分享前应审阅。
路径分配不是跨进程文件锁。本地包检查环境为 Windows、R 4.4.1；其他环境以 CI 实际结果为准。
取消编辑会报错并保留赋值目标的原值；关闭窗口后需等待连接断开被检测到。窗口移动、缩放和拖放仍需人工验收，自动化逻辑测试不替代这些检查。

## 设计参考、反馈与许可

`list_edit()` 的工具栏、完成/取消和导出理念参考
[Dillon Hammill 的 DataEditR](https://github.com/DillonHammill/DataEditR)。独立列网格为自行实现，未复制或打包 DataEditR 源码。

问题反馈：[GitHub Issues](https://github.com/cicada478/cic/issues)。本项目采用 [MIT 许可证](LICENSE.md)。
