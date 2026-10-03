#' Create a safe path for an analysis output
#'
#' `out()` applies a common naming and collision policy to paths used by any
#' file-writing function. It does not write the requested output itself.
#'
#' @param path A single, non-empty output path. When `ext` is supplied, `path`
#'   is treated as a stem and must not already have a different extension.
#' @param ext Optional extension, with or without a leading dot.
#' @param tag Optional character vector of filename tags. Tags are inserted
#'   between the stem and timestamp and joined with underscores.
#' @param timestamp `FALSE` to disable the timestamp, `TRUE` for `%Y%m%d`, or a
#'   format string accepted by [base::format()]. Defaults to the
#'   `cic.out.timestamp` option, or `%Y%m%d` when that option is unset.
#' @param conflict How to handle an existing destination: `"ask"` (the
#'   default) shows an interactive menu and falls back to `"increment"` in
#'   non-interactive sessions; `"increment"` finds an unused numbered name;
#'   `"error"` stops; and `"overwrite"` returns the existing path.
#' @param dir Optional output directory. Defaults to the `cic.out.dir` option,
#'   if set. An explicit directory in `path` is preserved inside `dir`.
#' @param create_dir Whether to create missing parent directories.
#' @param log `TRUE` records the allocated path in `.cic_outputs.csv` beside
#'   the output, `FALSE` disables logging, and a character value specifies a
#'   log file explicitly.
#' @return Invisibly, the final output path.
#' @details Calling `out()` records a path allocation. The writing function is
#'   called afterwards, so [outputs()] reports whether the file now exists and
#'   makes failed or abandoned writes visible. Path allocation is not a file
#'   lock; concurrent processes still need their own synchronization.
#' @export
#' @examples
#' out(tempfile("markers", fileext = ".csv"), log = FALSE)
#' out(tempfile("seurat"), ext = "rds", tag = "final", log = FALSE)
out <- function(path, ext = NULL, tag = NULL,
                timestamp = getOption("cic.out.timestamp", "%Y%m%d"),
                conflict = getOption("cic.out.conflict", "ask"),
                dir = getOption("cic.out.dir", NULL), create_dir = TRUE,
                log = getOption("cic.out.log", TRUE)) {
  assert_scalar_string(path, "path")
  assert_flag(create_dir, "create_dir")

  if (!is.null(dir)) {
    assert_scalar_string(dir, "dir")
    path <- file.path(dir, path)
  }

  if (!is.null(ext)) {
    assert_scalar_string(ext, "ext")
    ext <- sub("^\\.", "", ext)
    if (!nzchar(ext) || grepl("[/\\\\]", ext)) {
      stop("`ext` must be a filename extension, not a path.", call. = FALSE)
    }
    current_ext <- tools::file_ext(path)
    if (nzchar(current_ext) && !identical(tolower(current_ext), tolower(ext))) {
      stop("`path` already has extension .", current_ext,
           "; remove it or use `ext = \"", current_ext, "\"`.", call. = FALSE)
    }
    if (!nzchar(current_ext)) path <- paste0(path, ".", ext)
  }

  if (!is.null(tag)) {
    if (!is.character(tag) || !length(tag) || anyNA(tag) ||
        any(!nzchar(tag)) || any(grepl("[/\\\\]", tag))) {
      stop("`tag` must contain non-empty character values without path separators.",
           call. = FALSE)
    }
    path <- add_filename_suffix(path, paste0("_", paste(tag, collapse = "_")))
  }

  if (isTRUE(timestamp)) timestamp <- "%Y%m%d"
  if (!identical(timestamp, FALSE)) {
    assert_scalar_string(timestamp, "timestamp")
    stamp <- format(Sys.time(), timestamp)
    if (grepl("[/\\\\]", stamp)) {
      stop("`timestamp` must not produce path separators.", call. = FALSE)
    }
    path <- add_filename_suffix(path, paste0("_", stamp))
  }

  conflict <- match.arg(conflict, c("ask", "increment", "error", "overwrite"))
  requested <- path
  action <- "new"
  if (file.exists(path)) {
    resolved <- resolve_output_conflict(path, conflict)
    path <- resolved$path
    action <- resolved$action
  }

  parent <- dirname(path)
  if (!dir.exists(parent)) {
    if (!create_dir) {
      stop("Output directory does not exist: ", parent, call. = FALSE)
    }
    if (!dir.create(parent, recursive = TRUE, showWarnings = FALSE) &&
        !dir.exists(parent)) {
      stop("Cannot create output directory: ", parent, call. = FALSE)
    }
  }

  log_file <- output_log_file(path, log)
  if (!is.null(log_file)) {
    tryCatch(
      append_output_log(log_file, path, requested, action),
      error = function(e) warning("Could not update output log: ",
                                  conditionMessage(e), call. = FALSE)
    )
  }

  invisible(path)
}

#' Inspect paths allocated by [out()]
#'
#' @param log A `.cic_outputs.csv` file or a directory containing one. By
#'   default, uses `cic.out.dir` or the current working directory.
#' @param existing Keep all records (`NA`, the default), only files that exist
#'   (`TRUE`), or only missing files (`FALSE`).
#' @param n Maximum number of most recent records to return.
#' @return A data frame ordered from newest to oldest, with an `exists` column
#'   computed when the function is called.
#' @export
#' @examples
#' td <- tempfile("cic-outputs-")
#' dir.create(td)
#' path <- out(file.path(td, "table.csv"), timestamp = FALSE)
#' write.csv(data.frame(x = 1), path, row.names = FALSE)
#' outputs(td)
#' unlink(td, recursive = TRUE)
outputs <- function(log = getOption("cic.out.dir", "."), existing = NA,
                    n = Inf) {
  assert_scalar_string(log, "log")
  if (dir.exists(log) || !grepl("\\.csv$", log, ignore.case = TRUE)) {
    log <- file.path(log, ".cic_outputs.csv")
  }
  if (!is.logical(existing) || length(existing) != 1L) {
    stop("`existing` must be TRUE, FALSE, or NA.", call. = FALSE)
  }
  if (!is.numeric(n) || length(n) != 1L || is.na(n) || n < 0 ||
      (!is.infinite(n) && n != floor(n))) {
    stop("`n` must be one non-negative whole number or Inf.", call. = FALSE)
  }
  if (!file.exists(log)) {
    message("No cic output log found at: ", log)
    return(empty_output_log())
  }

  ans <- utils::read.csv(log, stringsAsFactors = FALSE,
                         colClasses = "character", check.names = FALSE)
  required <- c("time", "file", "requested", "action", "script")
  if (!all(required %in% names(ans))) {
    stop("Invalid cic output log: required columns are missing.", call. = FALSE)
  }
  ans$exists <- file.exists(ans$file)
  if (!is.na(existing)) ans <- ans[ans$exists == existing, , drop = FALSE]
  ans <- ans[rev(seq_len(nrow(ans))), , drop = FALSE]
  if (is.finite(n) && nrow(ans) > n) ans <- ans[seq_len(n), , drop = FALSE]
  rownames(ans) <- NULL
  ans
}

resolve_output_conflict <- function(path, conflict) {
  if (identical(conflict, "ask")) {
    if (interactive()) {
      choice <- utils::menu(
        c("Auto-rename / \u81ea\u52a8\u91cd\u547d\u540d",
          "Overwrite / \u8986\u76d6", "Cancel / \u53d6\u6d88"),
        title = paste("File already exists:", path)
      )
      conflict <- if (choice == 1L) "increment" else if (choice == 2L) {
        "overwrite"
      } else {
        stop("Output cancelled.", call. = FALSE)
      }
    } else {
      conflict <- "increment"
    }
  }

  if (identical(conflict, "increment")) {
    renamed <- auto_rename(path)
    message("Output already exists; using: ", renamed)
    return(list(path = renamed, action = "increment"))
  }
  if (identical(conflict, "error")) {
    stop("Output file already exists:\n  ",
         normalizePath(path, mustWork = FALSE), call. = FALSE)
  }
  list(path = path, action = "overwrite")
}

output_log_file <- function(path, log) {
  if (identical(log, FALSE) || is.null(log)) return(NULL)
  if (identical(log, TRUE)) return(file.path(dirname(path), ".cic_outputs.csv"))
  assert_scalar_string(log, "log")
  if (dir.exists(log)) file.path(log, ".cic_outputs.csv") else log
}

append_output_log <- function(log, path, requested, action) {
  parent <- dirname(log)
  if (!dir.exists(parent) &&
      !dir.create(parent, recursive = TRUE, showWarnings = FALSE) &&
      !dir.exists(parent)) {
    stop("Cannot create log directory: ", parent)
  }
  record <- data.frame(
    time = format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
    file = normalizePath(path, winslash = "/", mustWork = FALSE),
    requested = normalizePath(requested, winslash = "/", mustWork = FALSE),
    action = action,
    script = active_script(),
    stringsAsFactors = FALSE
  )
  present <- file.exists(log) && file.info(log)$size > 0
  utils::write.table(record, log, sep = ",", row.names = FALSE,
                     col.names = !present, append = present, qmethod = "double",
                     fileEncoding = "UTF-8")
  invisible(log)
}

active_script <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  script_arg <- grep("^--file=", args, value = TRUE)
  if (length(script_arg)) return(sub("^--file=", "", script_arg[[1L]]))
  frames <- rev(sys.frames())
  for (frame in frames) {
    if (!is.null(frame$ofile) && is.character(frame$ofile)) return(frame$ofile)
  }
  NA_character_
}

empty_output_log <- function() {
  data.frame(time = character(), file = character(), requested = character(),
             action = character(), script = character(), exists = logical(),
             stringsAsFactors = FALSE)
}

assert_scalar_string <- function(x, name) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    stop(sprintf("`%s` must be a single non-empty character string.", name),
         call. = FALSE)
  }
}

assert_flag <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop(sprintf("`%s` must be TRUE or FALSE.", name), call. = FALSE)
  }
}
