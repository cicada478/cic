# cic

面向单细胞分析日常工作的 R 工具集：统一输出路径、记录输出文件、保存图形，以及交互式编辑 marker genes、颜色和细胞类型顺序。

<div class="pkgdown-devel">
这是开发版文档，可能包含尚未发布的功能。请通过 GitHub Releases 核对已发布版本；开发预览不会覆盖稳定网站。
</div>

<div class="pkgdown-release">
这是正式发布版本的文档，参数和教程对应页面顶部显示的包版本。
</div>

## 按任务开始

| 任务 | 函数 | 教程 |
|---|---|---|
| 分配输出路径、查询日志 | [`out()`](reference/out.html)、[`outputs()`](reference/outputs.html) | [输出管理与绘图保存](articles/safe-outputs.html) |
| 保存 ggplot 图形 | [`ggsave1()`](reference/ggsave1.html) | [绘图保存](articles/safe-outputs.html#plots) |
| 输入、粘贴和调整列表顺序 | [`list_edit()`](reference/list_edit.html) | [列表编辑器](articles/list-editor.html) |

```r
# 单列自动返回字符向量，多列自动返回命名 list
cell_order <- cic::list_edit()
```

完整参数与返回值见函数参考，变更见 [更新记录](news/index.html)。安装方式见 [仓库 README](https://github.com/cicada478/cic#readme)，正式版本与源代码包见 [GitHub Releases](https://github.com/cicada478/cic/releases)。

## English

cic provides output-path allocation, output logs, plot export and interactive list editing for everyday analysis. Start with [safe outputs](articles/safe-outputs.html#english) or the [list editor](articles/list-editor.html#english); both guides include English instructions. The version in the navigation bar identifies this documentation build. Development previews are separate from the release website.

Workflow inspired by [DataEditR](https://github.com/DillonHammill/DataEditR). The list editor is implemented independently in cic.
