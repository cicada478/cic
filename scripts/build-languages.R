# Build each language from isolated sources so search and page bodies never mix.
build_languages <- function(mode, source_ref) {
  project <- normalizePath(".", winslash = "/")
  destination <- sub("/+$", "", file.path(project, "docs", if (mode == "devel") "dev" else ""))
  scratch <- tempfile("cic-docs-")
  dir.create(scratch)
  on.exit(unlink(scratch, recursive = TRUE), add = TRUE)
  site <- file.path(scratch, "site")
  dir.create(site)
  config <- yaml::read_yaml("_pkgdown.yml")
  base_url <- sub("/+$", "", config$url)
  if (mode == "devel") base_url <- paste0(base_url, "/dev")
  for (language in c("zh", "en")) {
    stage <- file.path(scratch, language)
    dir.create(stage)
    entries <- c("DESCRIPTION", "NAMESPACE", "LICENSE", "LICENSE.md",
                 "R", "man", "inst", "vignettes", "NEWS.md")
    stopifnot(all(file.copy(entries, stage, recursive = TRUE)))
    dir.create(file.path(stage, "pkgdown"))
    english <- language == "en"
    homepage <- if (english) "pkgdown/en/index.md" else "pkgdown/index.md"
    file.copy(homepage, file.path(stage, "pkgdown/index.md"))
    news <- readLines(if (english) "inst/doc/NEWS.en.md" else "NEWS.md", encoding = "UTF-8")
    news <- news[!grepl("简体中文.*English", news)]
    writeLines(news, file.path(stage, "NEWS.md"), useBytes = TRUE)
    for (article in c("safe-outputs", "list-editor")) {
      target <- file.path(stage, "vignettes", paste0(article, ".Rmd"))
      if (english) {
        file.copy(file.path("pkgdown/en/articles", paste0(article, ".Rmd")), target, overwrite = TRUE)
      } else {
        lines <- readLines(target, encoding = "UTF-8")
        cutoff <- which(grepl("^## English", lines))
        stopifnot(length(cutoff) == 1L)
        lines <- lines[seq_len(cutoff - 1L)]
        lines <- lines[!grepl("^\\[English\\]", lines)]
        # Keep slash-separated shortcuts and code intact: only titles are translated.
        original <- readLines(target, encoding = "UTF-8")[seq_len(cutoff - 1L)]
        lines <- original[!grepl("^\\[English\\]", original)]
        titles <- grepl("^title:|VignetteIndexEntry", lines)
        lines[titles] <- sub(" / [^\"}]+", "", lines[titles])
        if (article == "safe-outputs") {
          lines <- c(lines, "```{r cleanup, include=FALSE}", "unlink(result_dir, recursive = TRUE)", "```")
        } else {
          lines <- c(lines, "## 设计参考", "", "工具栏、完成/取消和导出理念参考 [Dillon Hammill 的 DataEditR](https://github.com/DillonHammill/DataEditR)。本包独立实现，不包含其源码。")
        }
        writeLines(lines, target, useBytes = TRUE)
      }
    }
    if (!english) {
      for (topic in c("out", "outputs", "ggsave1", "list_edit")) {
        translated <- file.path("pkgdown/zh/reference", paste0(topic, ".Rd"))
        canonical <- file.path("man", paste0(topic, ".Rd"))
        usage <- function(path) {
          rd <- tools::parse_Rd(path)
          item <- Filter(function(x) identical(attr(x, "Rd_tag"), "\\usage"), rd)
          gsub("[[:space:]]", "", paste(unlist(item), collapse = ""))
        }
        if (!identical(usage(translated), usage(canonical))) {
          stop("Translated usage is out of sync: ", topic)
        }
        file.copy(translated, file.path(stage, "man", paste0(topic, ".Rd")), overwrite = TRUE)
      }
    }
    local_config <- config
    local_config$url <- paste0(base_url, if (english) "/en/" else "/")
    local_config$lang <- if (english) "en" else "zh_CN"
    local_config$home <- list(title = if (english) "Tools for everyday analysis" else "日常分析效率工具",
      description = if (english) "Output paths, logs, plot export and interactive list editing in R." else "用于 R 分析的输出路径管理、日志查询、图形保存与交互式列表编辑工具。")
    # Keep pkgdown's standard non-empty development prefix. Build separately,
    # then assemble / and /en/; newer pkgdown filters site paths by this prefix.
    local_config$destination <- file.path(scratch, paste0("build-", language))
    local_config$development <- list(mode = mode, destination = "dev")
    local_config$repo$url$source <- paste0("https://github.com/cicada478/cic/blob/", source_ref, "/")
    local_config$navbar$components <- list(
      reference = list(text = if (english) "Reference" else "函数参考", href = "reference/index.html"),
      articles = list(text = if (english) "Guides" else "使用教程", menu = list(
        list(text = if (english) "Safe analysis outputs" else "输出管理与绘图保存", href = "articles/safe-outputs.html"),
        list(text = if (english) "List editor" else "列表编辑器", href = "articles/list-editor.html"))),
      news = list(text = if (english) "Changelog" else "更新记录", href = "news/index.html"),
      language = list(text = if (english) "简体中文" else "English", href = "language.html"))
    if (english) {
      local_config$reference[[1L]]$title <- "Output management"
      local_config$reference[[2L]]$title <- "Plot export"
      local_config$reference[[3L]]$title <- "List editing"
      local_config$articles[[1L]]$title <- "Guides"
    }
    yaml::write_yaml(local_config, file.path(stage, "_pkgdown.yml"))
    pkgdown::build_site(stage, preview = FALSE, new_process = FALSE, install = FALSE)
    built <- file.path(local_config$destination, if (mode == "devel") "dev" else "")
    target <- file.path(site, if (english) "en" else "")
    dir.create(target, showWarnings = FALSE)
    stopifnot(all(file.copy(list.files(built, full.names = TRUE, all.files = TRUE, no.. = TRUE), target, recursive = TRUE)))
  }
  source(file.path(project, "scripts/localize-site.R"), local = TRUE)
  localize_site(site, base_url)
  # Replace only this generated output directory after both builds succeed.
  # Refuse symlinks/junctions that resolve outside the intended project path.
  if (dir.exists(destination)) {
    if (!identical(normalizePath(destination, winslash = "/"), destination)) {
      stop("Unexpected generated output path: ", destination)
    }
    unlink(destination, recursive = TRUE)
  }
  dir.create(destination, recursive = TRUE, showWarnings = FALSE)
  stopifnot(all(file.copy(list.files(site, full.names = TRUE, all.files = TRUE, no.. = TRUE), destination, recursive = TRUE)))
}
