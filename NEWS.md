# cic v0.2.0：安全输出路径与输出日志

**简体中文** | [English](inst/doc/NEWS.en.md)

发布日期：2026-10-03

`cic` 0.2.0 新增统一的分析输出路径策略。现在，`saveRDS()`、
`write.csv()`、`ggsave()`、`qs2::qs_save()` 以及其他接受目标路径的保存函数，
都可以共用日期后缀、重名保护、目录创建和日志规则。

## 重点变化

- 新增 `out()`：与具体保存函数解耦的路径管理器，默认添加日期、创建父目录，
  并保护已有文件。
- 新增四种冲突策略：交互选择、自动编号、报错和覆盖。默认保护模式在交互式
  R 中显示菜单，在非交互环境中自动编号。
- 新增 `ext` 与 `tag` 语法糖，可生成
  `fibroblast_final_20261003.rds` 一类分析文件名。
- 新增 `outputs()` 和按目录保存的 `.cic_outputs.csv` 日志。查询结果会实时添加
  `exists` 字段，让保存失败或中止的路径仍然可见。
- 新增 `cic.out.dir`、`cic.out.timestamp`、`cic.out.conflict` 和
  `cic.out.log` 项目级选项。

## 行为变化

- `ggsave1()` 现在将命名、冲突处理、目录创建和日志交给 `out()`；原有参数仍然
  可用。
- 包版本更新为 `0.2.0`，中英文文档均增加了统一输出工作流说明。
- 新增 Windows 与 Ubuntu 的 GitHub Actions `R CMD check` 工作流，并将第三方
  Action 固定到确切修订版本。
- 增加完整 MIT 许可证正文并扩充包测试。

## 兼容性与迁移

`ggsave1()` 没有有意引入破坏性 API 变更。新增的默认副作用是：每次分配路径时
会在输出目录记录 `.cic_outputs.csv`。如不需要日志，可全局关闭：

```r
options(cic.out.log = FALSE)
```

日志包含绝对本地路径，并可能包含脚本名。本仓库已忽略该文件；公开分析结果前，
请删除日志，或确认其内容已经过审查并适合披露。

`v0.2.0` 使用新的干净 Git 历史。旧提交、tag、Release、Issue 和 Pull Request
保留在 [`cic-legacy`](https://github.com/cicada478/cic-legacy)。现有 `v0.1.x`
clone 应重新克隆，不要使用 `--allow-unrelated-histories` 合并新旧历史。

## 已知限制

- `out()` 在保存函数运行前分配路径；应使用 `outputs()` 判断目标文件最终是否
  产生。
- 路径分配不是跨进程文件锁。并行 worker 写同一名称时仍需同步，或使用
  worker 特定的标签。
- 日志保存在各输出目录旁。可以调用 `outputs("目录")`；设置 `cic.out.dir`
  后也可以直接调用 `outputs()`。

## 验证

`0.2.0` 候选版本已在 Windows 11、R 4.4.1 上完成本地检查：

```text
R CMD check --no-manual cic_0.2.0.tar.gz
Status: OK
```

检查范围包括包安装、帮助示例、`ggsave1()` 真实 PDF 输出测试，以及新增的命名、
冲突、日志、筛选和参数校验测试。仓库 CI 已配置 Windows 与 Ubuntu 的当前 R
release；远端结果应在发布前以对应候选提交的 GitHub Actions 运行记录为准。

## 发布后安装

```r
install.packages("remotes")
remotes::install_github("cicada478/cic@v0.2.0")
```

Release 同时提供 `cic_0.2.0.tar.gz` 与 `SHA256SUMS`。下载后可使用
`sha256sum -c SHA256SUMS` 验证源码包。
