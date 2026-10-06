# cic

[简体中文](https://github.com/cicada478/cic/blob/main/README.md) | **English**

`cic` is a small R workflow package for managing explicit analysis outputs. It
applies one naming policy to RDS, CSV, PDF, PNG, QS2, and other files: add a
date, prevent silent overwrites, and keep a queryable allocation log.

This document describes version `0.3.0`. `cic` only handles paths
passed explicitly to `out()` or `ggsave1()`; it does not monitor the filesystem
or rename package caches and temporary files.
Starting with 0.3.0, path operations use `fs` as an internal backend; naming,
collision, and logging policies remain defined by `cic`.

## Repository migration

`v0.2.0` starts from a newly reviewed, clean Git history. The `v0.1.x`
commits, tags, Releases, issues, and pull requests remain permanently available
in [`cic-legacy`](https://github.com/cicada478/cic-legacy).

If an existing clone came from `v0.1.x`, clone this repository again. Do not
combine the histories with `--allow-unrelated-histories`:

```sh
git clone https://github.com/cicada478/cic.git
```

## Features

- `out()` supplies timestamp, tag, directory, and collision policies to any
  writer that accepts a path.
- `outputs()` reads allocation logs and checks whether each target now exists.
- `ggsave1()` keeps its convenient `ggsave()` interface while sharing the same
  file-safety policy.
- Project options centralize the output directory, timestamp format, collision
  behavior, and logging switch.

## Quick start

### Install

Install the development version from GitHub:

```r
install.packages("remotes")
remotes::install_github("cicada478/cic")
```

The current stable release is `v0.3.0`. Install that exact version with:

```r
remotes::install_github("cicada478/cic@v0.3.0")
```

The Release also provides a verified R source package:

```r
install.packages(
  "https://github.com/cicada478/cic/releases/download/v0.3.0/cic_0.3.0.tar.gz",
  repos = NULL,
  type = "source"
)
```

Download `SHA256SUMS` from the same Release and run
`sha256sum -c SHA256SUMS`. On Windows PowerShell, compare it with
`Get-FileHash cic_0.3.0.tar.gz -Algorithm SHA256`.

For a local source checkout, install `fs` and `ggplot2`, then run this from
the repository root:

```r
install.packages(c("fs", "ggplot2"))
install.packages(".", repos = NULL, type = "source")
```

### First safe output

```r
library(cic)

path <- out("results/markers.csv")
write.csv(mtcars, path, row.names = FALSE)

path
# "results/markers_20261003.csv"

outputs("results")
```

`out()` returns a safe path; the original writer still serializes the object.
The same policy therefore works across file formats:

```r
saveRDS(seu, out("results/seurat.rds"))
readr::write_csv(markers, out("results/markers.csv"))
qs2::qs_save(seu, out("results/seurat.qs2"))
ggplot2::ggsave(out("results/umap.pdf"), p)
```

## Naming and collision protection

The default suffix is the local date in `_YYYYMMDD` form. When a destination
exists, interactive R offers auto-rename, overwrite, and cancel. Non-interactive
sessions select the first unused `_1`, `_2`, and so on without prompting.

| `conflict` | Behavior |
|---|---|
| `"ask"` | Interactive menu; automatic incrementing in batch sessions |
| `"increment"` | Select the first unused numbered path |
| `"error"` | Stop when the target exists |
| `"overwrite"` | Explicitly permit the writer to replace the target |

```r
out("markers.csv", conflict = "increment")
out("markers.csv", conflict = "error")
out("markers.csv", conflict = "overwrite")

out("markers.csv", timestamp = FALSE)
out("markers.csv", timestamp = "%Y%m%d_%H%M%S")
```

## `ext` and `tag` syntax sugar

```r
out("fibroblast", ext = "rds", tag = "final")
# "fibroblast_final_20261003.rds"

out("umap", ext = ".pdf", tag = c("fib", "dpw7"))
# "umap_fib_dpw7_20261003.pdf"
```

An extension that conflicts with the one already present in `path` is rejected
instead of producing an easy-to-miss name such as `table.csv.rds`.

## Output logs

By default, `out()` appends to `.cic_outputs.csv` beside the target. Each record
contains the allocation time, final path, pre-collision path, selected action,
and the script name when it can be detected.

```r
outputs("results")
outputs("results", existing = TRUE, n = 20)
outputs("results", existing = FALSE)
```

`outputs()` computes `exists` at query time. If the writer fails after receiving
a path, the allocation remains visible with `exists = FALSE`.

The log contains absolute local paths and may contain a script name. This
repository ignores `.cic_outputs.csv`; remove or review it before sharing an
analysis directory.

```r
out("result.csv", log = FALSE)
options(cic.out.log = FALSE)
out("result.csv", log = "logs/analysis-outputs.csv")
```

## Project configuration

Explicit function arguments override these ordinary R options:

| Option | Default | Purpose |
|---|---:|---|
| `cic.out.dir` | `NULL` | Shared output root |
| `cic.out.timestamp` | `"%Y%m%d"` | A `format()` string, or `FALSE` |
| `cic.out.conflict` | `"ask"` | Default collision policy |
| `cic.out.log` | `TRUE` | Whether to record allocations |

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

Missing parent directories are created by default. Set `create_dir = FALSE` to
require them to exist already.

## Save ggplot figures

```r
library(ggplot2)
library(cic)

p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()

ggsave1("figures/scatter.pdf", p, width = 6, height = 4)
ggsave1("last_plot.png", width = 6, height = 4, dpi = 300)
ggsave1("scatter.pdf", p, add_date = FALSE)
ggsave1("scatter.pdf", p, path = "figures", width = 6, height = 4)
```

`confirm = FALSE` remains the explicit overwrite switch for existing code:

```r
ggsave1("scatter.pdf", p, confirm = FALSE, add_date = FALSE)
```

`ggsave1()` invisibly returns the final path and shares `out()`'s timestamp,
collision, directory, and logging behavior.

## 0.3.0 path backend

Starting with 0.3.0, `cic` uses `fs` for path decomposition, extensions,
existence checks, directory creation, and internal log paths. `fs` remains an
implementation detail: `out()` still returns a plain character value and
preserves 0.2.0's caller-visible path representation, dotfile naming,
collision policies, options, and log columns.

This change does not make allocation a file lock and does not monitor writes
performed by other packages. Concurrent writers still require external
synchronization or distinct tags.

## Limitations and compatibility

- `out()` allocates a path before the writer runs; use `outputs()` to verify
  that the file was ultimately created.
- Allocation is not a cross-process file lock. Concurrent workers targeting
  the same name need separate synchronization or worker-specific tags.
- Logs live beside their outputs. Without `cic.out.dir`, pass a non-current
  output directory to `outputs()` explicitly.
- Local validation used Windows 11, R 4.4.1, fs 2.1.0, and ggplot2 4.0.3. CI is configured
  to run the current R release on Windows and Ubuntu. Consult GitHub Actions for
  observed results; this is not a compatibility guarantee for every R or OS
  version.

## Development and validation

From the repository root:

```sh
R CMD build .
R CMD check --no-manual cic_0.3.0.tar.gz
```

The check runs examples, `tests/output.R`, and `tests/ggsave1.R`. The current
0.3.0 candidate produced `Status: OK` in the local environment above.

See [the English release notes](NEWS.en.md) for release changes. Report
problems through
[GitHub Issues](https://github.com/cicada478/cic/issues) and propose code changes
through pull requests. Use a minimal sanitized example; do not post credentials,
private data, or an unreviewed `.cic_outputs.csv`.

## License

This project is available under the
[MIT License](https://github.com/cicada478/cic/blob/main/LICENSE.md). Copyright
information is recorded in the repository's
[LICENSE](https://github.com/cicada478/cic/blob/main/LICENSE) file.
