# cic

R utilities for everyday single-cell analysis: allocate output paths, track output files, save plots, and interactively edit marker genes, colours and cell-type orders.

<div class="pkgdown-devel">
This is development documentation and may describe unreleased changes. Check GitHub Releases for published versions; development previews do not replace the stable website.
</div>

<div class="pkgdown-release">
This documentation describes the released package version shown in the navigation bar.
</div>

## Start with your task

| Task | Functions | Guide |
|---|---|---|
| Allocate output paths and inspect logs | [`out()`](reference/out.html), [`outputs()`](reference/outputs.html) | [Safe analysis outputs](articles/safe-outputs.html) |
| Save ggplot figures | [`ggsave1()`](reference/ggsave1.html) | [Save plots](articles/safe-outputs.html#plots) |
| Enter, paste and reorder lists | [`list_edit()`](reference/list_edit.html) | [List editor](articles/list-editor.html) |

```r
# One final column returns a character vector; multiple columns return a named list.
cell_order <- cic::list_edit()
```

See the function reference for complete arguments and return values, and the [changelog](news/index.html) for version history. Installation instructions are in the [repository README](https://github.com/cicada478/cic/blob/main/inst/doc/README.en.md); published versions and source packages are available from [GitHub Releases](https://github.com/cicada478/cic/releases).

## Acknowledgement

Workflow inspired by [DataEditR](https://github.com/DillonHammill/DataEditR). The list editor is implemented independently in cic.
