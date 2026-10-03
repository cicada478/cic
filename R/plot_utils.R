#' Save a plot with a date suffix and overwrite protection
#'
#' Wraps [ggplot2::ggsave()] for convenient plot export. By default, a date
#' suffix (`_YYYYMMDD`, using the local date) is inserted before the extension.
#' Missing parent directories are created automatically.
#'
#' @param filename A single, non-empty filename, optionally including a path.
#' @param plot Plot to save. Defaults to [ggplot2::last_plot()].
#' @param ... Additional arguments passed to [ggplot2::ggsave()], including
#'   `path`, `device`, `width`, `height`, `units`, and `dpi`.
#' @param confirm Logical. If `TRUE` (default), an existing destination triggers
#'   an interactive menu offering overwrite, automatic renaming, or cancellation.
#'   In a non-interactive session, an existing destination is automatically renamed.
#'   Set `FALSE` to explicitly allow overwriting without a prompt.
#' @param add_date Logical. Whether to append the date; defaults to `TRUE`.
#' @return Invisibly, the final destination filename, including `path` if supplied.
#' @details File naming, collision handling, directory creation, and output
#'   logging are delegated to [out()]. Automatic renaming appends `_1`, `_2`,
#'   and so on before the extension, selecting the first unused filename.
#' @export
#' @examples
#' p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
#' output <- ggsave1(tempfile(fileext = ".pdf"), p, width = 5, height = 4)
#' unlink(output)
ggsave1 <- function(filename, plot = ggplot2::last_plot(), ...,
                    confirm = TRUE, add_date = TRUE) {
  if (!is.character(filename) || length(filename) != 1L ||
      is.na(filename) || !nzchar(filename)) {
    stop("`filename` must be a single non-empty character string.", call. = FALSE)
  }
  for (flag in c("confirm", "add_date")) {
    value <- get(flag)
    if (!is.logical(value) || length(value) != 1L || is.na(value)) {
      stop(sprintf("`%s` must be TRUE or FALSE.", flag), call. = FALSE)
    }
  }

  args <- list(...)
  if (!is.null(args$path)) {
    if (!is.character(args$path) || length(args$path) != 1L ||
        is.na(args$path)) {
      stop("`path` must be a single character string or NULL.", call. = FALSE)
    }
    filename <- file.path(args$path, filename)
    args$path <- NULL
  }
  filename <- out(filename,
                  timestamp = if (add_date) "%Y%m%d" else FALSE,
                  conflict = if (confirm) "ask" else "overwrite")

  do.call(ggplot2::ggsave, c(list(filename = filename, plot = plot), args))
  invisible(filename)
}

# Internal filename helpers; not exported.
add_filename_suffix <- function(filename, suffix) {
  ext <- tools::file_ext(filename)
  base <- tools::file_path_sans_ext(filename)
  paste0(base, suffix, if (nzchar(ext)) paste0(".", ext) else "")
}

auto_rename <- function(filename) {
  i <- 1L
  repeat {
    newname <- add_filename_suffix(filename, paste0("_", i))
    if (!file.exists(newname)) return(newname)
    i <- i + 1L
  }
}
