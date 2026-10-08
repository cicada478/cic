# cic v0.3.1: Path and log safety fixes

[简体中文](https://github.com/cicada478/cic/blob/main/NEWS.md) | **English**

Release date: TBD

- Absolute `path` values now take precedence over `dir` and `cic.out.dir`
  instead of being appended to the output root.
- Before appending to a non-empty existing log, `cic` now requires the exact
  log columns in the expected order. Ordinary CSV files are rejected without
  modification.
- `outputs()` now reports malformed CSV and incompatible log schemas with a
  stable error that includes the affected log path.
- Added regression coverage for absolute paths, ordinary CSV files, empty and
  valid logs, reordered columns, and malformed logs.

# cic v0.3.0: fs-backed output paths

[简体中文](https://github.com/cicada478/cic/blob/main/NEWS.md) | **English**

Release date: 2026-10-06

- `out()`, `outputs()`, `ggsave1()`, and their internal filename helpers now
  use `fs` for path decomposition, extensions, existence checks, directory
  creation, and internal path operations. Caller-visible path strings retain
  their 0.2.0 representation.
- The public arguments, four collision policies, options, log columns, default
  behavior, and plain-character return type of `out()` remain unchanged.
- Added regression coverage for Unicode and space-containing directories,
  return types, and a parent path that is a file rather than a directory.
- `fs` is an internal filesystem backend only. Path allocation is still not a
  cross-process lock, and logs still describe allocations made before a writer
  runs.

# cic v0.2.0: Safe output paths and output logs

[简体中文](https://github.com/cicada478/cic/blob/main/NEWS.md) | **English**

Release date: 2026-10-03

`cic` 0.2.0 introduces a common output-path policy for R analysis workflows.
It lets `saveRDS()`, `write.csv()`, `ggsave()`, `qs2::qs_save()`, and other
functions that accept a destination path share timestamp, collision, directory,
and logging rules.

## Highlights

- Added `out()`, a writer-independent path manager that adds a date suffix,
  creates parent directories, and protects existing files.
- Added four explicit collision policies: interactive selection, automatic
  incrementing, error, and overwrite. The default protective mode shows a menu
  in interactive R and automatically increments in non-interactive sessions.
- Added `ext` and `tag` syntax sugar for names such as
  `fibroblast_final_20261003.rds`.
- Added `outputs()` and per-directory `.cic_outputs.csv` logs. The query adds a
  live `exists` field so failed or abandoned writes remain visible.
- Added project-level configuration through `cic.out.dir`,
  `cic.out.timestamp`, `cic.out.conflict`, and `cic.out.log` options.

## Changed

- `ggsave1()` now delegates naming, collision handling, directory creation,
  and logging to `out()`. Its existing arguments remain available.
- The package version is now 0.2.0 and the user documentation covers the
  shared output workflow in Chinese and English.
- Added a Windows and Ubuntu GitHub Actions workflow for `R CMD check`, with
  third-party actions pinned to exact revisions.
- Added the full MIT license text and expanded package validation tests.

## Compatibility and migration

There are no intentional breaking API changes to `ggsave1()`. One new side
effect is that it records path allocations in `.cic_outputs.csv` by default.
Disable all output logging when needed with:

```r
options(cic.out.log = FALSE)
```

The allocation log contains absolute local paths and may contain a script
name. It is ignored by this repository and should not be published with
analysis results unless it has been reviewed and intentionally sanitized.

`v0.2.0` starts from a new, clean Git history. Previous commits, tags,
Releases, issues, and pull requests remain in
[`cic-legacy`](https://github.com/cicada478/cic-legacy). Existing `v0.1.x`
clones should be replaced with a fresh clone; do not combine the histories
with `--allow-unrelated-histories`.

## Known limitations

- `out()` allocates a path before the writer runs. Use `outputs()` to determine
  whether the target file was ultimately created.
- Path allocation is not a cross-process file lock. Concurrent workers writing
  the same name require separate synchronization or worker-specific tags.
- Logs are stored beside each output. Call `outputs("directory")`, or set
  `cic.out.dir` and call `outputs()` without an argument.

## Verification

The 0.2.0 candidate was checked locally on Windows 11 with R 4.4.1:

```text
R CMD check --no-manual cic_0.2.0.tar.gz
Status: OK
```

The check ran package installation, examples, the existing real-PDF
`ggsave1()` tests, and the new output naming, collision, logging, filtering,
and argument-validation tests. CI is configured for the current R release on
Windows and Ubuntu; the corresponding candidate commit's GitHub Actions result
must be checked before release.

## Install after release

```r
install.packages("remotes")
remotes::install_github("cicada478/cic@v0.2.0")
```

The Release also includes `cic_0.2.0.tar.gz` and `SHA256SUMS`. After
downloading both files, run `sha256sum -c SHA256SUMS` to verify the package.
