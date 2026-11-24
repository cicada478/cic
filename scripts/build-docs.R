# Default to a development preview. Stable deployment requires a published Release.
args <- commandArgs(trailingOnly = TRUE)
channel <- if (length(args)) args[[1L]] else "development"
stopifnot(channel %in% c("development", "release"))
version <- read.dcf("DESCRIPTION", fields = "Version")[[1L]]
if (channel == "release") {
  if (Sys.getenv("GITHUB_EVENT_NAME") != "release" ||
      Sys.getenv("GITHUB_REPOSITORY") != "cicada478/cic") {
    stop("Stable documentation requires a Release event in cicada478/cic.")
  }
  event <- jsonlite::fromJSON(Sys.getenv("GITHUB_EVENT_PATH"))
  if (!identical(event$action, "published") ||
      !identical(event$release$draft, FALSE) ||
      !identical(event$release$prerelease, FALSE) ||
      !identical(event$release$tag_name, paste0("v", version))) {
    stop("Release must be published, stable and match DESCRIPTION Version.")
  }
}
mode <- if (channel == "release") "release" else "devel"
Sys.setenv(PKGDOWN_DEV_MODE = mode)
# Rscript already provides a clean process; report warnings in the build log.
options(warn = 1)
source_ref <- if (channel == "release") paste0("v", version) else "main"
pkgdown::build_site(override = list(
  development = list(mode = mode),
  repo = list(url = list(source = paste0(
    "https://github.com/cicada478/cic/blob/", source_ref, "/")))),
  preview = FALSE, new_process = FALSE)
