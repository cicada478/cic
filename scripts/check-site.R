# Validate local destinations and HTML anchors without network access.
args <- commandArgs(trailingOnly = TRUE)
root <- normalizePath(if (length(args)) args[[1L]] else "docs/dev",
                      winslash = "/", mustWork = TRUE)
files <- list.files(root, pattern = "\\.html$", recursive = TRUE, full.names = TRUE)
stopifnot(length(files) > 0L)
failures <- character()
for (file in files) {
  doc <- xml2::read_html(file)
  relative <- substring(file, nchar(root) + 2L)
  english <- startsWith(relative, "en/")
  expected_lang <- if (english) "en" else "zh-CN"
  if (!identical(xml2::xml_attr(xml2::xml_find_first(doc, "//html"), "lang"), expected_lang)) {
    failures <- c(failures, paste(file, "-> incorrect document language"))
  }
  switches <- xml2::xml_find_all(doc, "//nav//a[contains(@class, 'cic-language-switch')]")
  if (length(switches) != 1L) {
    failures <- c(failures, paste(file, "-> expected one language switch"))
  } else {
    other <- normalizePath(file.path(dirname(file), xml2::xml_attr(switches, "href")),
                           winslash = "/", mustWork = FALSE)
    counterpart <- if (english) substring(relative, 4L) else paste0("en/", relative)
    expected <- normalizePath(file.path(root, counterpart), winslash = "/", mustWork = FALSE)
    if (!identical(other, expected) || !file.exists(other)) {
      failures <- c(failures, paste(file, "-> language switch does not preserve the page"))
    }
  }
  if (english) {
    prose <- xml2::xml_text(xml2::xml_find_all(doc, "//main//text()[not(ancestor::pre or ancestor::code or ancestor::script)]"))
    if (any(grepl("[一-鿿]", prose, perl = TRUE))) {
      failures <- c(failures, paste(file, "-> Chinese prose in English content"))
    }
  }
  repeated <- xml2::xml_find_all(doc, "//main//a[@href='#english' or contains(@href, 'NEWS.en.md')]")
  if (length(repeated)) failures <- c(failures, paste(file, "-> repeated in-body language links"))
  hrefs <- xml2::xml_attr(xml2::xml_find_all(doc, "//a[@href]"), "href")
  assets <- xml2::xml_find_all(doc, "//img[@src]|//script[@src]|//link[@rel='stylesheet' or @rel='icon' or @rel='apple-touch-icon']")
  asset_urls <- ifelse(xml2::xml_name(assets) == "link", xml2::xml_attr(assets, "href"), xml2::xml_attr(assets, "src"))
  hrefs <- c(hrefs, asset_urls[!is.na(asset_urls)])
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
for (language in c("", "en")) {
  index <- file.path(root, language, "search.json")
  if (!file.exists(index)) {
    failures <- c(failures, paste(index, "-> missing language-specific search index"))
  } else {
    if (language == "en" && any(grepl("[一-鿿]", readLines(index, warn = FALSE, encoding = "UTF-8"), perl = TRUE))) {
      failures <- c(failures, paste(index, "-> Chinese content in English search index"))
    }
    metadata <- yaml::read_yaml(file.path(root, language, "pkgdown.yml"))
    prefix <- sub("reference/?$", "", metadata$urls$reference)
    entries <- jsonlite::fromJSON(index)
    for (path in unique(entries$path)) {
      relative <- if (startsWith(path, prefix)) substring(path, nchar(prefix) + 1L) else path
      if (!file.exists(file.path(root, language, relative))) {
        failures <- c(failures, paste(index, "-> invalid search destination", path))
      }
    }
  }
}
if (length(failures)) stop(paste(unique(failures), collapse = "\n"))
cat("Checked language pairing, isolated search, local links and anchors in", length(files), "HTML pages.\n")
