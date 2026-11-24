#' Interactively create or edit independent character lists
#'
#' UI workflow inspired by Dillon Hammill's DataEditR. The independent-column
#' editor is implemented in cic; no DataEditR code is bundled.
#'
#' @param x A vector, non-empty list of simple vectors, or data frame. Values
#'   are converted to text. `NULL` opens one empty column. Use either `x` or
#'   `file`, not both.
#' @param output Return type. `"auto"` (default) returns a character vector for
#'   one final column and a named list for multiple final columns. Empty columns
#'   count. `"list"` always returns a named list, even for one column.
#'   `"vector"` requires exactly one column and disables adding columns.
#' @param file Optional UTF-8 delimited text path to load instead of `x`.
#'   [data.table::fread()] detects the separator (e.g. CSV, TSV or semicolon).
#'   The first non-empty row contains column names. Values, including `001`,
#'   literal `NA` and surrounding whitespace, stay text. UTF-8 BOM is supported.
#'   Quote values containing separators or double quotes; escape embedded double
#'   quotes by doubling them. Excel and R binary files are not supported.
#' @param viewer Where to open the editor. `"auto"` (default) and `"window"`
#'   prefer a standalone Edge/Chrome app window on Windows when an executable
#'   is found; otherwise they use the default browser. `"window"` reports the
#'   fallback when no supported executable is found. `"browser"` explicitly uses the default browser, which may open
#'   a tab. `"dialog"` requires RStudio and rstudioapi and retains RStudio's
#'   movement and resize restrictions. Standalone windows have native desktop
#'   movement, resize and maximize controls; they are not always-on-top windows.
#' @return A character vector or named list of character vectors, selected by
#'   `output`. An empty single column in auto mode returns `character(0)`.
#'   Cancel or browser disconnection raises an error, leaving an existing
#'   assignment target unchanged. Exporting CSV does not commit the R result.
#' @details
#' Requires interactive R and optional packages shiny and jsonlite. Editing
#' occupies the R session until Done or Cancel. Closing the browser is detected
#'   after disconnection; it may not be instantaneous. No variables are assigned
#'   automatically in the global environment and no input file is overwritten.
#'
#' Each column is independent. Blank/whitespace-only cells and R missing values
#' are omitted; other whitespace, duplicate values, case and order are preserved.
#' Names must be non-blank and unique. Element-level vector names are discarded;
#' a single column's title is not retained in vector output. Formula-like input
#' is plain text. This is not a relational table editor: do not use separate
#' independent columns to reorder paired cell types and colours together.
#'
#' Enter moves down, Tab moves right and wraps, and Shift reverses those moves.
#' Escape moves from a cell to the toolbar; Alt+Up/Down reorders the current item.
#' Paste tab/newline-separated text into a cell. Drag item handles within a
#' column or header handles to reorder columns. Arrow buttons are alternatives.
#' Undo/Redo also restore deleted columns. Cross-column drag is not supported.
#'
#' Export CSV downloads UTF-8 text, padding shorter columns with empty cells.
#' R code displays a reproducible expression generated with [base::dput()],
#' using the same return-type rule as Done. Assign that expression in a script
#' for non-interactive reuse. Clipboard access may require manual Ctrl+C.
#' @seealso [out()], [outputs()], [ggsave1()]
#' @references Workflow and export concepts inspired by
#'   [Dillon Hammill's DataEditR](https://github.com/DillonHammill/DataEditR).
#'   No DataEditR source code is bundled and DataEditR is not a dependency.
#' @export
#' @examples
#' if (interactive() && requireNamespace("shiny", quietly = TRUE) &&
#'     requireNamespace("jsonlite", quietly = TRUE)) {
#'   cell_order <- list_edit() # One final column -> character vector
#'   markers <- list_edit(list(T_cell = c("CD3D", "CD3E")), output = "list")
#'   genes <- list_edit(output = "vector", viewer = "browser")
#'   # RStudio only: list_edit(viewer = "dialog")
#' }
list_edit <- function(x = NULL, output = c("auto", "list", "vector"), file = NULL,
                      viewer = c("auto", "window", "dialog", "browser")) {
  output <- match.arg(output)
  viewer <- match.arg(viewer)
  if (!is.null(file)) {
    if (!is.null(x)) stop("Supply either `x` or `file`, not both.", call. = FALSE)
    x <- list_edit_read(file)
  }
  initial <- list_edit_normalize(x)
  if (output == "vector" && length(initial) != 1L)
    stop("Vector output requires exactly one column.", call. = FALSE)
  if (!interactive()) stop("`list_edit()` requires an interactive R session.", call. = FALSE)
  for (pkg in c("shiny", "jsonlite")) {
    if (!requireNamespace(pkg, quietly = TRUE))
      stop(sprintf("Install the optional package '%s' to use list_edit().", pkg), call. = FALSE)
  }
  launch <- shiny::browserViewer()
  has_dialog <- requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()
  if (viewer == "dialog" && !has_dialog)
    stop("The dialog viewer requires RStudio and rstudioapi; use viewer = 'browser'.", call. = FALSE)
  if (viewer == "dialog")
    launch <- shiny::dialogViewer("cic list editor", width = 1000, height = 720)
  if (viewer %in% c("auto", "window")) {
    browser <- list_edit_window_browser()
    if (nzchar(browser)) {
      launch <- function(url) {
        status <- system2(browser, args = c(shQuote(paste0("--app=", url)),
          "--new-window", "--window-size=1100,800"), wait = FALSE)
        if (!identical(status, 0L)) utils::browseURL(url)
      }
    } else if (viewer == "window") {
      message("No supported standalone browser found; opening in your browser.")
    }
  }
  result <- shiny::runApp(list_edit_app(initial, output), launch.browser = launch)
  if (is.null(result)) stop("List editing cancelled; no result was assigned.", call. = FALSE)
  result
}

# Chromium app windows have native desktop resize/move controls. No browser
# profile or user preferences are changed. Other platforms use browserViewer.
list_edit_window_browser <- function() {
  if (.Platform$OS.type != "windows") return("")
  roots <- Sys.getenv(c("ProgramFiles(x86)", "ProgramFiles", "LOCALAPPDATA"))
  roots <- roots[nzchar(roots)]
  candidates <- c(unname(Sys.which(c("msedge", "chrome"))),
    file.path(roots, "Microsoft", "Edge", "Application", "msedge.exe"),
    file.path(roots, "Google", "Chrome", "Application", "chrome.exe"))
  candidates <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (length(candidates)) candidates[[1L]] else ""
}

list_edit_normalize <- function(x) {
  if (is.null(x)) x <- list(list1 = character())
  if (is.atomic(x) && is.null(dim(x))) x <- list(list1 = x)
  if (!is.list(x) || !length(x) || (!is.data.frame(x) && !is.null(dim(x))))
    stop("Use a vector, a non-empty list of vectors, or a data frame.", call. = FALSE)
  nm <- names(x)
  if (is.null(nm)) nm <- paste0("list", seq_along(x))
  if (anyNA(nm) || any(!nzchar(trimws(nm))) || anyDuplicated(nm))
    stop("Column names must be non-empty and unique.", call. = FALSE)
  ans <- lapply(x, function(v) {
    if (!is.null(v) && (!is.atomic(v) || !is.null(dim(v))))
      stop("Each column must be a simple vector.", call. = FALSE)
    v <- as.character(v)
    unname(v[!is.na(v) & nzchar(trimws(v))])
  })
  structure(ans, names = nm)
}

list_edit_read <- function(file) {
  if (!is.character(file) || length(file) != 1L || is.na(file) || !nzchar(file))
    stop("`file` must be a single delimited text path.", call. = FALSE)
  # Read the header as text too: fread otherwise replaces blank column names.
  # Escalate parser warnings so truncated/partially parsed input is not accepted.
  tab <- withCallingHandlers(
    data.table::fread(file = file, sep = "auto", header = FALSE, skip = 0L,
      colClasses = "character", na.strings = NULL, strip.white = FALSE,
      check.names = FALSE, encoding = "UTF-8", fill = FALSE,
      blank.lines.skip = TRUE, data.table = FALSE, showProgress = FALSE),
    warning = function(w) stop("Cannot read list file: ", conditionMessage(w),
                               call. = FALSE))
  if (!nrow(tab) || !ncol(tab))
    stop("The list file must contain a header row.", call. = FALSE)
  # fread retains doubled quotes inside quoted fields. Decode the standard
  # CSV/TSV quote escape, including in headers, for Export CSV round-trips.
  tab[] <- lapply(tab, function(x) gsub('""', '"', x, fixed = TRUE))
  header <- unname(unlist(tab[1L, , drop = FALSE], use.names = FALSE))
  tab <- tab[-1L, , drop = FALSE]
  names(tab) <- header
  tab
}

list_edit_table <- function(x) {
  n <- max(lengths(x), 0L)
  as.data.frame(lapply(x, function(v) c(v, rep("", n - length(v)))),
                optional = TRUE, stringsAsFactors = FALSE)
}

list_edit_decode <- function(columns, output) {
  if (!is.list(columns) || !length(columns)) stop("Add at least one column.")
  nm <- vapply(columns, function(col) {
    if (!is.character(col$name) || length(col$name) != 1L) stop("Invalid column name.")
    col$name
  }, character(1))
  values <- lapply(columns, function(col) {
    v <- unlist(col$values, use.names = FALSE)
    if (!is.null(v) && !is.character(v)) stop("Cells must contain text.")
    v
  })
  result <- list_edit_normalize(structure(values, names = nm))
  if (output == "vector" || (output == "auto" && length(result) == 1L)) {
    if (length(result) != 1L) stop("Vector output requires exactly one column.")
    return(result[[1L]])
  }
  result
}

list_edit_app <- function(initial, output) {
  asset <- function(name) system.file("list-edit", name, package = "cic", mustWork = TRUE)
  config <- jsonlite::toJSON(list(columns = lapply(seq_along(initial), function(i)
    list(name = names(initial)[i], values = unname(initial[[i]]))), output = output),
    auto_unbox = TRUE, force = TRUE)
  # Keep user text out of executable script contexts, including </script>.
  config <- gsub("<", "\\u003c", config, fixed = TRUE)
  ui <- shiny::fluidPage(
    shiny::tags$head(shiny::includeCSS(asset("editor.css"))),
    shiny::tags$main(id = "cic-editor",
      shiny::tags$header(shiny::tags$div(shiny::tags$small("cic / LIST WORKSPACE"),
        shiny::tags$h1("List editor"), shiny::tags$p("One column, one list. Keep your order.")),
        shiny::tags$div(class = "actions", shiny::tags$button(id = "cancel", "Cancel"),
          shiny::tags$button(id = "done", class = "primary", "Done & return"))),
      shiny::tags$nav(class = "toolbar", `aria-label` = "Editor tools",
        shiny::tags$button(id = "add", "Add column"),
        shiny::tags$button(id = "undo", "Undo"), shiny::tags$button(id = "redo", "Redo"),
        shiny::tags$button(id = "csv", "Export CSV"),
        shiny::tags$button(id = "code", "R code")),
      shiny::tags$div(class = "hint", `aria-label` = "Editing shortcuts",
        shiny::tags$span(shiny::tags$kbd("Enter"), " Next item in this column"),
        shiny::tags$span(shiny::tags$kbd("Tab"), " Next column; wraps to the next row"),
        shiny::tags$span(shiny::tags$kbd("Shift + Enter / Tab"), " Move in reverse"),
        shiny::tags$span(shiny::tags$kbd("Alt + Up / Down"), " Reorder the current item"),
        shiny::tags$span(shiny::tags$kbd("Esc"), " Focus the toolbar")),
      shiny::tags$p(class = "hint-detail", "Paste tab-separated columns or one item per line. Drag an item's handle to reorder within its column; drag a header handle to move a column. Click Done & return to send the result back to R."),
      shiny::tags$div(id = "error", role = "alert"),
      shiny::tags$div(id = "grid", `aria-label` = "Independent lists"),
      shiny::tags$section(id = "code-panel", hidden = "hidden",
        shiny::tags$label(`for` = "r-code", "Reproducible R code"),
        shiny::tags$textarea(id = "r-code", readonly = "readonly", rows = 7),
        shiny::tags$button(id = "copy-code", "Copy code")),
      shiny::tags$footer(shiny::tags$span(id = "status", role = "status"))),
    shiny::tags$script(id = "cic-config", type = "application/json", shiny::HTML(config)),
    shiny::includeScript(asset("editor.js")))
  server <- function(input, output, session) {
    session$onSessionEnded(function() shiny::stopApp(NULL))
    shiny::observeEvent(input$edit_action, {
      action <- input$edit_action
      if (identical(action$kind, "cancel")) { shiny::stopApp(NULL); return() }
      tryCatch({
        value <- list_edit_decode(action$columns, output_type)
        if (identical(action$kind, "done")) shiny::stopApp(value)
        if (identical(action$kind, "code")) session$sendCustomMessage("cic-code",
          paste(utils::capture.output(dput(value)), collapse = "\n"))
        if (identical(action$kind, "csv")) {
          cols <- list_edit_decode(action$columns, "list")
          csv <- character()
          con <- textConnection("csv", "w", local = TRUE)
          tryCatch(utils::write.csv(list_edit_table(cols), con, row.names = FALSE, na = ""),
                   finally = close(con))
          session$sendCustomMessage("cic-csv", paste(csv, collapse = "\r\n"))
        }
      }, error = function(e) session$sendCustomMessage("cic-error", conditionMessage(e)))
    })
  }
  output_type <- output
  shiny::shinyApp(ui, server)
}
