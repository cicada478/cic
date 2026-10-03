library(cic)

run_checks <- function() {
  output_dir <- tempfile("cic-tests-")
  dir.create(output_dir)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()

  expect_error <- function(expr, pattern) {
    err <- tryCatch({ force(expr); NULL }, error = identity)
    stopifnot(inherits(err, "error"), grepl(pattern, conditionMessage(err)))
  }

  # A real PDF export checks the date, path handling, directory creation,
  # argument forwarding, and invisible return value together.
  target_dir <- file.path(output_dir, "nested", "figures")
  result <- withVisible(ggsave1("plot.pdf", p, path = target_dir,
                                width = 3, height = 2))
  expected <- file.path(target_dir, paste0("plot_", format(Sys.Date(), "%Y%m%d"), ".pdf"))
  stopifnot(identical(result$value, expected), !result$visible,
            file.exists(expected), file.info(expected)$size > 0)

  # Non-interactive collisions save to unused numbered paths without overwriting.
  stopifnot(!interactive())
  checksum <- tools::md5sum(expected)
  renamed <- withVisible(ggsave1("plot.pdf", p, path = target_dir,
                                 width = 3, height = 2))
  first_numbered <- sub("\\.pdf$", "_1.pdf", expected)
  stopifnot(identical(renamed$value, first_numbered), !renamed$visible,
            identical(rawToChar(readBin(first_numbered, "raw", n = 4L)), "%PDF"))
  first_checksum <- tools::md5sum(first_numbered)
  second_numbered <- ggsave1("plot.pdf", p, path = target_dir,
                             width = 3, height = 2)
  stopifnot(identical(second_numbered, sub("\\.pdf$", "_2.pdf", expected)),
            file.exists(second_numbered),
            identical(first_checksum, tools::md5sum(first_numbered)))
  stopifnot(identical(checksum, tools::md5sum(expected)))

  # Explicit overwrite replaces a sentinel file with a real PDF.
  fixed <- file.path(output_dir, "fixed.pdf")
  writeLines("sentinel", fixed)
  stopifnot(identical(ggsave1(fixed, p, confirm = FALSE, add_date = FALSE,
                             width = 3, height = 2), fixed))
  stopifnot(identical(rawToChar(readBin(fixed, "raw", n = 4L)), "%PDF"))

  # Automatic renaming skips occupied suffixes and preserves extensions.
  rename <- getFromNamespace("auto_rename", "cic")
  occupied <- file.path(output_dir, "fixed_1.pdf")
  file.create(occupied)
  stopifnot(identical(rename(fixed), file.path(output_dir, "fixed_2.pdf")))
  fixed_checksums <- tools::md5sum(c(fixed, occupied))
  fixed_renamed <- ggsave1(fixed, p, add_date = FALSE, width = 3, height = 2)
  stopifnot(identical(fixed_renamed, file.path(output_dir, "fixed_2.pdf")),
            identical(rawToChar(readBin(fixed_renamed, "raw", n = 4L)), "%PDF"),
            identical(fixed_checksums, tools::md5sum(c(fixed, occupied))))

  # Explicit devices also support filenames without an extension.
  plain <- file.path(output_dir, "no_extension")
  dated <- ggsave1(plain, p, device = "pdf", width = 3, height = 2)
  stopifnot(identical(dated, paste0(plain, format(Sys.Date(), "_%Y%m%d"))),
            file.exists(dated), identical(rename(plain), paste0(plain, "_1")))

  # The default plot is the last ggplot object.
  default <- ggsave1(file.path(output_dir, "last.pdf"), width = 3, height = 2)
  stopifnot(file.exists(default))

  expect_error(ggsave1(NA_character_, p), "filename")
  expect_error(ggsave1("invalid.pdf", p, confirm = NA), "confirm")
  expect_error(ggsave1("invalid.pdf", p, add_date = 1), "add_date")
  expect_error(ggsave1("invalid.pdf", p, path = c("a", "b")), "path")
}

run_checks()
