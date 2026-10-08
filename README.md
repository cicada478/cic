# cic

**简体中文** | [English](inst/doc/README.en.md)

`cic` 是一个面向 R 分析工作流的轻量工具包：用统一的路径策略管理主动
输出，为 RDS、CSV、PDF、PNG、QS2 等结果添加日期、防止静默覆盖，并记录
可查询的输出日志。

本文档对应开发版本 `0.3.1`；当前稳定版仍为 `0.3.0`。`cic` 只处理显式传给
`out()` 或 `ggsave1()`
的路径，不监听文件系统，因此不会改写其他包的 cache、临时文件或中间文件。
从 0.3.0 起，路径操作统一使用 `fs` 作为内部后端；命名、冲突和日志策略仍由
`cic` 定义。

## 仓库迁移说明

`v0.2.0` 使用经过重新审查的干净 Git 历史。`v0.1.x` 的提交、tag、Release、
Issue 和 Pull Request 永久保存在
[`cic-legacy`](https://github.com/cicada478/cic-legacy)。

如果本地 clone 来自 `v0.1.x`，请重新克隆本仓库；不要使用
`--allow-unrelated-histories` 合并两段历史：

```sh
git clone https://github.com/cicada478/cic.git
```

## 主要功能

- `out()`：为任何接受文件路径的保存函数提供日期、标签、目录和重名策略。
- `outputs()`：查询路径分配日志，并实时检查目标文件是否已经产生。
- `ggsave1()`：保留熟悉的 `ggsave()` 包装，同时复用 `out()` 的文件安全逻辑。
- 项目级选项：集中设置输出目录、时间格式、冲突策略和日志开关。

## 快速开始

### 安装

安装 GitHub 上的开发版本：

```r
install.packages("remotes")
remotes::install_github("cicada478/cic")
```

当前稳定版为 `v0.3.0`，可固定安装该版本：

```r
remotes::install_github("cicada478/cic@v0.3.0")
```

也可以安装 Release 中经过校验的 R 源码包：

```r
install.packages(
  "https://github.com/cicada478/cic/releases/download/v0.3.0/cic_0.3.0.tar.gz",
  repos = NULL,
  type = "source"
)
```

同一 Release 提供 `SHA256SUMS`。下载两个文件后可运行
`sha256sum -c SHA256SUMS`；Windows PowerShell 用户也可以用
`Get-FileHash cic_0.3.0.tar.gz -Algorithm SHA256` 对照检查。

从本地源码安装时，需要先安装 `fs` 和 `ggplot2`，再在仓库根目录运行：

```r
install.packages(c("fs", "ggplot2"))
install.packages(".", repos = NULL, type = "source")
```

### 第一个安全输出

```r
library(cic)

path <- out("results/markers.csv")
write.csv(mtcars, path, row.names = FALSE)

path
# "results/markers_20261003.csv"

outputs("results")
```

`out()` 不负责序列化对象；它先返回经过安全处理的路径，再由原有保存函数写入。
因此同一套策略可以用于不同文件格式：

```r
saveRDS(seu, out("results/seurat.rds"))
readr::write_csv(markers, out("results/markers.csv"))
qs2::qs_save(seu, out("results/seurat.qs2"))
ggplot2::ggsave(out("results/umap.pdf"), p)
```

## 命名与重名保护

默认在扩展名前添加本地日期 `_YYYYMMDD`：

```r
out("umap.pdf")
# "umap_20261003.pdf"
```

如果目标已经存在，默认保护模式的行为是：

- 交互式 R/RStudio：显示“自动重命名 / 覆盖 / 取消”菜单；
- `Rscript`、测试和批处理：自动使用第一个未占用的 `_1`、`_2`……路径。

也可以为单次输出显式选择策略：

| `conflict` | 行为 |
|---|---|
| `"ask"` | 交互式菜单；非交互环境自动编号 |
| `"increment"` | 直接寻找第一个未占用的编号 |
| `"error"` | 目标存在时停止 |
| `"overwrite"` | 明确允许后续保存函数覆盖 |

```r
out("markers.csv", conflict = "increment")
out("markers.csv", conflict = "error")
out("markers.csv", conflict = "overwrite")
```

关闭日期后缀或使用更精细的时间格式：

```r
out("markers.csv", timestamp = FALSE)
out("markers.csv", timestamp = "%Y%m%d_%H%M%S")
```

## `ext` 和 `tag` 语法糖

`ext` 可以带或不带前导点；`tag` 可以是一个或多个标签：

```r
out("fibroblast", ext = "rds", tag = "final")
# "fibroblast_final_20261003.rds"

out("umap", ext = ".pdf", tag = c("fib", "dpw7"))
# "umap_fib_dpw7_20261003.pdf"
```

如果 `path` 已经带有与 `ext` 不一致的扩展名，`out()` 会报错，避免生成
`table.csv.rds` 一类容易忽略的文件名。

## 输出日志

默认情况下，`out()` 会在目标文件同目录追加 `.cic_outputs.csv`。每条记录包含
分配时间、最终路径、冲突前路径、处理动作，以及能够识别时的脚本名。

```r
outputs("results")
outputs("results", existing = TRUE, n = 20)
outputs("results", existing = FALSE)
```

`exists` 由 `outputs()` 查询时实时计算。保存函数如果在获得路径后失败，该记录会
保留，但显示 `exists = FALSE`，便于找到失败或尚未完成的输出。

日志含有绝对本地路径，并可能含有脚本名；本仓库已忽略
`.cic_outputs.csv`。将分析目录共享或公开前，应删除日志或确认其内容可以披露。

关闭日志：

```r
out("result.csv", log = FALSE)
options(cic.out.log = FALSE)
```

也可以将日志写到明确指定的位置：

```r
out("result.csv", log = "logs/analysis-outputs.csv")
```

为防止误伤已有数据，非空的自定义日志必须具有 `cic` 写出的精确字段顺序：
`time, file, requested, action, script`。普通 CSV 或字段顺序不同会在追加前被
拒绝，原文件保持不变；`outputs()` 还会将损坏的 CSV 报告为包含日志路径的错误。

## 项目级配置

`out()` 使用普通 R options；函数的显式参数优先于这些默认值。

| Option | 默认值 | 用途 |
|---|---:|---|
| `cic.out.dir` | `NULL` | 统一输出根目录 |
| `cic.out.timestamp` | `"%Y%m%d"` | `format()` 接受的时间格式；`FALSE` 关闭 |
| `cic.out.conflict` | `"ask"` | 默认冲突策略 |
| `cic.out.log` | `TRUE` | 是否记录路径分配 |

```r
options(
  cic.out.dir = "results",
  cic.out.timestamp = "%Y%m%d",
  cic.out.conflict = "ask",
  cic.out.log = TRUE
)

saveRDS(seu, out("seurat.rds"))
outputs()
```

`cic.out.dir` 只作用于相对路径。传给 `out()` 的绝对路径始终优先，并保持在其
原位置，不会拼接到项目输出根目录后。

缺失的父目录默认会自动创建。需要严格要求目录事先存在时，使用
`create_dir = FALSE`。

## 保存 ggplot 图形

```r
library(ggplot2)
library(cic)

p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()

ggsave1("figures/scatter.pdf", p, width = 6, height = 4)
ggsave1("last_plot.png", width = 6, height = 4, dpi = 300)
ggsave1("scatter.pdf", p, add_date = FALSE)
ggsave1("scatter.pdf", p, path = "figures", width = 6, height = 4)
```

`confirm = FALSE` 是显式覆盖开关，保留用于兼容已有代码：

```r
ggsave1("scatter.pdf", p, confirm = FALSE, add_date = FALSE)
```

`ggsave1()` 会不可见地返回实际保存路径，并与 `out()` 共用日期、重名保护、
目录创建和日志机制。

## 0.3.0 路径后端

从 0.3.0 起，`cic` 使用 `fs` 统一处理路径解析、扩展名、存在性检查、目录创建
和内部日志路径。`fs` 是实现细节：`out()` 仍返回普通 character，且保留 0.2.0
的调用者可见路径表示、隐藏文件命名、冲突策略、options 和日志列。

这一变化不会把路径分配变成文件锁，也不会监听其他包的文件写入。并行 writer
仍需要外部同步或各自不同的 `tag`。

## 限制与安全边界

- `out()` 分配路径时，实际保存尚未发生；使用 `outputs()` 检查文件最终是否产生。
- 路径分配不是跨进程文件锁。多个并行 worker 写同一名称时，需要额外同步，
  或使用 worker 特定的 `tag`。
- 日志按输出目录保存；未设置 `cic.out.dir` 时，查询非当前目录需要将目录传给
  `outputs()`。
- 本地验证环境为 Windows 11、R 4.4.1、fs 2.1.0、ggplot2 4.0.3。仓库 CI 配置为在
  Windows 和 Ubuntu 的当前 R release 上执行检查；具体结果以 GitHub Actions
  为准，这不构成对所有 R 或操作系统版本的兼容性承诺。

## 开发与验证

从仓库根目录运行：

```sh
R CMD build .
R CMD check --no-manual cic_0.3.0.tar.gz
```

检查会运行帮助示例、`tests/output.R` 和 `tests/ggsave1.R`。当前 `0.3.0`
候选版本在上述本地环境中的结果为：

```text
Status: OK
```

发布变更见 [NEWS.md](NEWS.md)。问题反馈请使用
[GitHub Issues](https://github.com/cicada478/cic/issues)，代码改进可通过 Pull
Request 提交。报告问题时请使用最小复现示例，不要粘贴凭据、私有数据或未经
清理的 `.cic_outputs.csv`。

## 许可证

本项目采用 [MIT License](LICENSE.md)。版权声明见 [LICENSE](LICENSE)。
