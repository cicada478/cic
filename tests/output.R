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
