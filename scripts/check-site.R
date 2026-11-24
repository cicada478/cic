# Validate local destinations and HTML anchors without network access.
args <- commandArgs(trailingOnly = TRUE)
root <- normalizePath(if (length(args)) args[[1L]] else "docs/dev",
                      winslash = "/", mustWork = TRUE)
files <- list.files(root, pattern = "\\.html$", recursive = TRUE, full.names = TRUE)
stopifnot(length(files) > 0L)
failures <- character()
for (file in files) {
  doc <- xml2::read_html(file)
  hrefs <- xml2::xml_attr(xml2::xml_find_all(doc, "//a[@href]"), "href")
  hrefs <- hrefs[!grepl("^([a-zA-Z][a-zA-Z0-9+.-]*:|//)", hrefs)]
  for (href in unique(hrefs)) {
    parts <- strsplit(href, "#", fixed = TRUE)[[1L]]
    path <- if (length(parts)) sub("\\?.*$", "", parts[[1L]]) else ""
    target <- if (!nzchar(path)) file else file.path(dirname(file), utils::URLdecode(path))
    if (dir.exists(target)) target <- file.path(target, "index.html")
    if (!file.exists(target)) {
      failures <- c(failures, paste(file, "->", href))
    } else if (length(parts) > 1L && nzchar(parts[[2L]]) && grepl("\\.html$", target)) {
      target_doc <- if (identical(target, file)) doc else xml2::read_html(target)
      ids <- xml2::xml_attr(xml2::xml_find_all(target_doc, "//*[@id]"), "id")
      names <- xml2::xml_attr(xml2::xml_find_all(target_doc, "//a[@name]"), "name")
      if (!utils::URLdecode(parts[[2L]]) %in% c(ids, names)) {
        failures <- c(failures, paste(file, "-> missing anchor", href))
      }
    }
  }
}
if (length(failures)) stop(paste(unique(failures), collapse = "\n"))
cat("Checked local links and anchors in", length(files), "HTML pages.\n")
