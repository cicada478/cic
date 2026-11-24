# cic

[简体中文](https://github.com/cicada478/cic/blob/main/README.md) | **English**

Everyday tools for R and single-cell analysis: save results safely, track output
paths, and enter or reorder independent lists.

**This documentation covers v0.4.1.** This version adds `list_edit()`
and retains `out()`, `outputs()` and `ggsave1()`. The editor requires interactive R
and occupies the R session until editing finishes.

## Choose a task

| Task | Function | Guide |
|---|---|---|
| Naming and collision rules for RDS, CSV and other output | `out()` | [Safe outputs](https://github.com/cicada478/cic/blob/main/vignettes/safe-outputs.Rmd) |
| Inspect allocated paths and current file existence | `outputs()` | [Output logs](https://github.com/cicada478/cic/blob/main/vignettes/safe-outputs.Rmd) |
| Save ggplot figures | `ggsave1()` | [Plot export](https://github.com/cicada478/cic/blob/main/vignettes/safe-outputs.Rmd) |
| Enter genes, colours or cell-type orders | `list_edit()` | [List editor](https://github.com/cicada478/cic/blob/main/vignettes/list-editor.Rmd) |

## Installation and versions

Check [GitHub Releases](https://github.com/cicada478/cic/releases) for published
versions and downloads. These instructions cover v0.4.1;
version 0.3.1 does not include `list_edit()`.

Download a source archive from Releases, restart R if cic is already loaded,
and install the downloaded file:

```r
install.packages(c("data.table", "fs", "ggplot2"))
install.packages("path/to/cic_VERSION.tar.gz", repos = NULL, type = "source")
```

To try this local copy, run from its package root, or install the locally built
`cic_0.4.1.tar.gz`:

```r
install.packages(c("data.table", "fs", "ggplot2"))
install.packages(".", repos = NULL, type = "source")
install.packages(c("shiny", "jsonlite")) # Editor only
# install.packages("rstudioapi")        # RStudio dialog only
library(cic)
packageVersion("cic")
```

Standalone windows use an existing Edge/Chrome executable. DataEditR is not a
dependency. Interactive UI dependencies (shiny and jsonlite) are optional for users of the output tools.

## Quick start

```r
path <- cic::out("results/markers.csv")
write.csv(data.frame(gene = c("CD3D", "MS4A1")), path, row.names = FALSE)
cic::outputs("results")

p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
cic::ggsave1("figures/scatter.pdf", p, width = 6, height = 4)

cell_order <- cic::list_edit()
markers <- cic::list_edit(list(T_cell = c("CD3D", "CD3E")), output = "list")
```

`out()` allocates a dated path, creates parent directories and handles collisions;
the writer creates the file. `outputs()` reports its current existence.
`ggsave1()` shares the output policy: collisions prompt in interactive R and use
automatic numbering in batch runs. `confirm = FALSE` skips confirmation and allows overwrite.
`Enter` moves down, `Tab` moves right, and handles reorder items in the editor.
**Done & return** returns the result to R. Editing occupies the R session.

## Return type and viewer

| Argument | Behaviour |
|---|---|
| `output = "auto"` (default) | One final column returns a character vector; multiple columns return a named list. Empty columns count. |
| `output = "list"` | Always returns a named list, including for one column. |
| `output = "vector"` | Requires one column and disables adding columns. |
| `viewer = "auto"` (default) | Prefers an existing Edge/Chrome app window on Windows; otherwise the default browser. |
| `viewer = "window"` | Same as auto; reports fallback when no supported executable is found. |
| `viewer = "browser"` | Uses the default browser, which may open a tab. |
| `viewer = "dialog"` | Requires RStudio and rstudioapi; retains the dialog's movement and resize restrictions. |

Standalone windows have native move, resize and maximize controls; they are not
always-on-top windows.

```r
genes <- cic::list_edit(output = "vector", viewer = "browser")
markers <- cic::list_edit(file = "markers.csv", output = "list")
# In RStudio:
cell_order <- cic::list_edit(viewer = "dialog")
```

Column names must be unique and non-blank. Blank cells are omitted; text such as
`001`, duplicates and order are preserved. Vector output discards the column
title; element-level names are not retained. Independent columns must not be
used to reorder paired cell types and colours together.

### File import

`file` uses `data.table::fread()` to detect CSV, TSV, semicolon-separated and other
UTF-8 delimited text, including a BOM. The first non-empty row supplies names.
All columns stay text, preserving literal `NA` and surrounding whitespace.
Quote values containing separators or double quotes; double embedded quotes. Parser warnings become errors rather than
returning partial data. Excel and R binary files are unsupported; export remains CSV.

## Documentation and status

Use `?cic::out`, `?cic::outputs`, `?cic::ggsave1` and `?cic::list_edit` for complete
arguments. Both guides have English sections. See [English news](NEWS.en.md)
and the [Chinese changelog](https://github.com/cicada478/cic/blob/main/NEWS.md),
or review the [v0.4.1 release notes](https://github.com/cicada478/cic/blob/main/releases/v0.4.1.md).

The pkgdown workflow deploys stable documentation only on a formal Release;
main/PR builds produce development preview artifacts. The planned address is
`https://cicada478.github.io/cic/`; availability depends on a successful Pages deployment. See
[maintenance instructions](https://github.com/cicada478/cic/blob/main/DEVELOPMENT.md).

## Limitations and validation scope

Logs record allocation, not successful writes, and contain absolute paths and
possibly script names: review them before sharing. Allocation is not a process
lock. Local checks ran on Windows with R 4.4.1; consult CI for other platforms.
Cancellation raises an error and preserves the assignment target. Closing a window
takes effect after disconnection is detected. Window movement, resizing and drag/drop
still require manual acceptance checks; automated logic tests do not replace them.

## Acknowledgements and support

Toolbar, Done/Cancel and export concepts were inspired by
[Dillon Hammill's DataEditR](https://github.com/DillonHammill/DataEditR).
The independent-column editor is original code; no DataEditR source is bundled.
Report issues on [GitHub](https://github.com/cicada478/cic/issues).
The project uses the [MIT license](https://github.com/cicada478/cic/blob/main/LICENSE.md).
