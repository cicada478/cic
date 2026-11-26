# Stable documentation describes a published Release; manual refreshes are docs-only.
args <- commandArgs(trailingOnly = TRUE)
channel <- if (length(args)) args[[1L]] else "development"
stopifnot(channel %in% c("development", "release"))
version <- read.dcf("DESCRIPTION", fields = "Version")[[1L]]
if (channel == "release") {
  if (!Sys.getenv("GITHUB_EVENT_NAME") %in% c("release", "workflow_dispatch") ||
      Sys.getenv("GITHUB_REPOSITORY") != "cicada478/cic") {
    stop("Stable documentation requires an authorized event in cicada478/cic.")
  }
  event <- jsonlite::fromJSON(Sys.getenv("GITHUB_EVENT_PATH"))
  if (Sys.getenv("GITHUB_EVENT_NAME") == "release") {
    if (!identical(event$action, "published") ||
      !identical(event$release$draft, FALSE) ||
      !identical(event$release$prerelease, FALSE) ||
      !identical(event$release$tag_name, paste0("v", version))) {
      stop("Release must be published, stable and match DESCRIPTION Version.")
    }
  } else {
    if (!identical(tolower(as.character(event$inputs$refresh_stable_docs)), "true") ||
        Sys.getenv("GITHUB_REF") != "refs/heads/main" ||
        Sys.getenv("DOCS_RELEASE_TAG") != paste0("v", version)) {
      stop("Documentation refresh must target the latest stable version from main.")
    }
    status <- system2("git", c("diff", "--exit-code", Sys.getenv("DOCS_RELEASE_TAG"),
                               "--", "DESCRIPTION", "NAMESPACE", "R", "inst/list-edit"))
    if (status != 0L) stop("Package code differs from the published release.")
  }
}
mode <- if (channel == "release") "release" else "devel"
Sys.setenv(PKGDOWN_DEV_MODE = mode)
# Rscript already provides a clean process; report warnings in the build log.
options(warn = 1)
source_ref <- if (channel == "release") paste0("v", version) else "main"
source("scripts/build-languages.R")
build_languages(mode, source_ref)
