library(cic)

run_output_checks <- function() {
  output_dir <- tempfile("cic-output-tests-")
  dir.create(output_dir)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  expect_error <- function(expr, pattern) {
    err <- tryCatch({ force(expr); NULL }, error = identity)
    stopifnot(inherits(err, "error"), grepl(pattern, conditionMessage(err)))
  }

  result <- withVisible(out(file.path(output_dir, "fibroblast"), ext = ".rds",
                            tag = c("final", "dpw7"), log = FALSE))
  expected <- file.path(
    output_dir,
    paste0("fibroblast_final_dpw7_", format(Sys.Date(), "%Y%m%d"), ".rds")
  )
  stopifnot(identical(result$value, expected),
            is.character(result$value), !inherits(result$value, "fs_path"),
            !result$visible,
            dir.exists(output_dir))

  unicode_path <- file.path(output_dir, "结果 空格", "细胞图.csv")
  unicode_result <- out(unicode_path, timestamp = FALSE, log = FALSE)
  stopifnot(identical(unicode_result, unicode_path),
            is.character(unicode_result),
            !inherits(unicode_result, "fs_path"),
            dir.exists(dirname(unicode_path)))

  hidden <- file.path(output_dir, ".hidden")
  hidden_result <- out(hidden, tag = "final", timestamp = FALSE, log = FALSE)
  stopifnot(identical(hidden_result,
                      file.path(output_dir, "_final.hidden")))

  fixed <- file.path(output_dir, "markers.csv")
  writeLines("original", fixed)
  stopifnot(!interactive())
  first <- out(fixed, timestamp = FALSE, log = FALSE)
  stopifnot(identical(first, file.path(output_dir, "markers_1.csv")))
  writeLines("number one", first)
  second <- out(fixed, timestamp = FALSE, conflict = "increment", log = FALSE)
  stopifnot(identical(second, file.path(output_dir, "markers_2.csv")),
            identical(readLines(fixed), "original"),
            identical(readLines(first), "number one"))

  stopifnot(identical(out(fixed, timestamp = FALSE, conflict = "overwrite",
                              log = FALSE), fixed))
  expect_error(out(fixed, timestamp = FALSE, conflict = "error", log = FALSE),
               "already exists")

  logged <- out(file.path(output_dir, "table.tsv"), timestamp = FALSE)
  stopifnot(file.exists(file.path(output_dir, ".cic_outputs.csv")))
  before <- outputs(output_dir)
  stopifnot(nrow(before) == 1L, identical(before$action, "new"),
            identical(before$exists, FALSE))
  writeLines("x\ty", logged)
  after <- outputs(output_dir, existing = TRUE)
  logged_normalized <- tolower(normalizePath(logged, winslash = "/"))
  recorded_normalized <- tolower(normalizePath(after$file, winslash = "/"))
  stopifnot(nrow(after) == 1L, identical(after$exists, TRUE),
            identical(recorded_normalized, logged_normalized))
  stopifnot(nrow(outputs(output_dir, existing = FALSE)) == 0L,
            nrow(outputs(output_dir, n = 0)) == 0L)

  option_dir <- file.path(output_dir, "results")
  old <- options(cic.out.dir = option_dir)
  on.exit(options(old), add = TRUE)
  option_path <- out("object", ext = "qs2", timestamp = FALSE)
  file.create(option_path)
  stopifnot(identical(option_path, file.path(option_dir, "object.qs2")),
            nrow(outputs()) == 1L, outputs()$exists[[1L]])
  options(old)

  absolute_path <- file.path(output_dir, "absolute", "result.csv")
  old <- options(cic.out.dir = file.path(output_dir, "ignored-option-dir"))
  on.exit(options(old), add = TRUE)
  absolute_result <- out(absolute_path, timestamp = FALSE, log = FALSE)
  stopifnot(identical(absolute_result, absolute_path),
            dir.exists(dirname(absolute_path)),
            !dir.exists(getOption("cic.out.dir")))
  explicit_dir_result <- out(
    absolute_path,
    dir = file.path(output_dir, "ignored-explicit-dir"),
    timestamp = FALSE,
    log = FALSE
  )
  stopifnot(identical(explicit_dir_result, absolute_path),
            !dir.exists(file.path(output_dir, "ignored-explicit-dir")))
  options(old)

  ordinary_log <- file.path(output_dir, "ordinary.csv")
  write.csv(data.frame(sample = "keep", value = 1), ordinary_log,
            row.names = FALSE)
  ordinary_before <- readBin(ordinary_log, "raw", n = file.info(ordinary_log)$size)
  expect_error(
    out(file.path(output_dir, "must-not-log.csv"), timestamp = FALSE,
        log = ordinary_log),
    "Invalid cic output log at:"
  )
  ordinary_after <- readBin(ordinary_log, "raw", n = file.info(ordinary_log)$size)
  stopifnot(identical(ordinary_after, ordinary_before))

  valid_log <- file.path(output_dir, "valid-log.csv")
  out(file.path(output_dir, "valid-one.csv"), timestamp = FALSE,
      log = valid_log)
  out(file.path(output_dir, "valid-two.csv"), timestamp = FALSE,
      log = valid_log)
  stopifnot(nrow(outputs(valid_log)) == 2L)

  empty_log <- file.path(output_dir, "empty-log.csv")
  file.create(empty_log)
  out(file.path(output_dir, "from-empty.csv"), timestamp = FALSE,
      log = empty_log)
  stopifnot(nrow(outputs(empty_log)) == 1L)

  reordered_log <- file.path(output_dir, "reordered-log.csv")
  writeLines("file,time,requested,action,script", reordered_log)
  expect_error(
    out(file.path(output_dir, "reordered.csv"), timestamp = FALSE,
        log = reordered_log),
    "Expected columns, in order"
  )

  malformed_log <- file.path(output_dir, "malformed-log.csv")
  writeLines(c("time,file,requested,action,script", "1,2,3,4,5,6,7"),
             malformed_log)
  expect_error(outputs(malformed_log), "Invalid cic output log at:")

  expect_error(out(NA_character_), "path")
  expect_error(out("x.csv", ext = "rds"), "already has extension")
  expect_error(out("x", tag = "bad/tag"), "tag")
  expect_error(out("x", timestamp = NA_character_), "timestamp")
  expect_error(out("x", timestamp = "%Y/%m"), "path separators")
  expect_error(out(file.path(output_dir, "missing", "x"), timestamp = FALSE,
                   create_dir = FALSE), "does not exist")
  blocked_parent <- file.path(output_dir, "not-a-directory")
  writeLines("file", blocked_parent)
  expect_error(out(file.path(blocked_parent, "x.csv"), timestamp = FALSE,
                   log = FALSE), "Cannot create output directory")
  expect_error(outputs(output_dir, existing = 1), "existing")
  expect_error(outputs(output_dir, n = 1.5), "whole number")
}

run_output_checks()
