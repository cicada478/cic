library(cic)
normalize <- cic:::list_edit_normalize
decode <- cic:::list_edit_decode
expect_error <- function(expr, pattern) {
  error <- tryCatch({force(expr); NULL}, error = identity)
  stopifnot(inherits(error, "error"), grepl(pattern, conditionMessage(error)))
}
original <- list(T_cell = c("CD3D", "", NA, "CD3D", "  ", "001", "NA"),
                 B_cell = "MS4A1", empty = character())
clean <- normalize(original)
stopifnot(identical(clean$T_cell, c("CD3D", "CD3D", "001", "NA")),
          identical(clean$empty, character()))
expect_error(normalize(list(a = 1, a = 2)), "unique")
expect_error(normalize(list(a = list("bad"))), "simple vector")
expect_error(normalize(list(" " = "bad")), "non-empty")
payload <- list(list(name = "B_cell", values = list("MS4A1")),
                list(name = "T_cell", values = list("CD3E", "CD3D", "")))
stopifnot(identical(decode(payload, "list"),
                    list(B_cell = "MS4A1", T_cell = c("CD3E", "CD3D"))),
          identical(decode(payload[1], "vector"), "MS4A1"))
expect_error(decode(payload, "vector"), "exactly one")
stopifnot(identical(formals(list_edit)$output, quote(c("auto", "list", "vector"))),
          identical(decode(payload[1], "auto"), "MS4A1"),
          identical(decode(payload, "auto"), decode(payload, "list")),
          identical(decode(payload[1], "list"), list(B_cell = "MS4A1")),
          identical(decode(list(list(name = "empty", values = list())), "auto"), character()),
          identical(decode(c(payload[1], list(list(name = "empty", values = list()))), "auto"),
                    list(B_cell = "MS4A1", empty = character())))
csv <- tempfile(fileext = ".csv")
utils::write.csv(cic:::list_edit_table(clean), csv, row.names = FALSE,
                 fileEncoding = "UTF-8")
stopifnot(identical(normalize(cic:::list_edit_read(csv)), clean))
unlink(csv)
# Delimited imports preserve text and validate the original (unrepaired) header.
read_text <- function(lines, bom = FALSE) {
  file <- tempfile("list input ", fileext = ".txt")
  on.exit(unlink(file))
  bytes <- charToRaw(enc2utf8(paste0(paste(lines, collapse = "\n"), "\n")))
  if (bom) bytes <- c(as.raw(c(239, 187, 191)), bytes)
  writeBin(bytes, file)
  normalize(cic:::list_edit_read(file))
}
stopifnot(identical(read_text(c("T cell\tB cell", "001\tNA", " CD3D \t#FF0000")),
                    list("T cell" = c("001", " CD3D "),
                         "B cell" = c("NA", "#FF0000"))),
          identical(read_text(c("T;B", "CD3D;MS4A1", ";CD79A")),
                    list(T = "CD3D", B = c("MS4A1", "CD79A"))),
          identical(read_text(c('"T, cell",B', '"a,b",NA', '"say ""hi""",001'), TRUE),
                    list("T, cell" = c("a,b", 'say "hi"'), B = c("NA", "001"))),
          identical(read_text(c("genes", "001", "NA")), list(genes = c("001", "NA"))),
          identical(read_text("a,b"), list(a = character(), b = character())),
          identical(read_text(c("a,b", "CD3D,MS4A1", "", "CD3E,CD79A")),
                    list(a = c("CD3D", "CD3E"), b = c("MS4A1", "CD79A"))))
expect_error(read_text(c("a,a", "x,y")), "unique")
expect_error(read_text(c("a,", "x,y")), "non-empty")
expect_error(read_text(c("a,b", "x,y", "z,w", "bad,row,extra")), "Cannot read list file")
expect_error(read_text(character()), "header row|Cannot read list file")
quoted <- list('a"b' = c('say "hi"', 'two "" quotes', "a,b", "line1\nline2"),
               colour = c("#FF0000", "001", "NA"))
csv <- tempfile(fileext = ".csv")
con <- file(csv, open = "wb")
utils::write.csv(cic:::list_edit_table(quoted), con, row.names = FALSE)
close(con)
stopifnot(identical(normalize(cic:::list_edit_read(csv)), quoted))
unlink(csv)
stopifnot(identical(read_text(c("\u57fa\u56e0,\u989c\u8272", "CD3D,#FF0000"), TRUE),
                    setNames(list("CD3D", "#FF0000"), c("\u57fa\u56e0", "\u989c\u8272"))))
empty <- list(a = character(), b = character())
stopifnot(nrow(cic:::list_edit_table(empty)) == 0L)
expect_error(list_edit(), "interactive")
expect_error(list_edit(list(a = "a", b = "b"), output = "vector"), "exactly one")

if (requireNamespace("shiny", quietly = TRUE) && requireNamespace("jsonlite", quietly = TRUE) &&
    requireNamespace("testthat", quietly = TRUE)) {
  app <- cic:::list_edit_app(list(a = "</script><script>alert(1)</script>"), "auto")
  shiny::testServer(app, {
    sent <- list()
    session$sendCustomMessage <- function(type, message) {
      sent[[type]] <<- message
    }
    session$setInputs(edit_action = list(kind = "code", columns = payload))
    stopifnot(identical(eval(parse(text = sent[["cic-code"]])), decode(payload, "list")))
    session$setInputs(edit_action = list(kind = "code", columns = payload[1]))
    stopifnot(identical(eval(parse(text = sent[["cic-code"]])), "MS4A1"))
    session$setInputs(edit_action = list(kind = "csv", columns = payload))
    stopifnot(grepl('"B_cell","T_cell"', sent[["cic-csv"]], fixed = TRUE))
    bad <- payload
    bad[[2]]$name <- "B_cell"
    session$setInputs(edit_action = list(kind = "done", columns = bad))
    stopifnot(grepl("unique", sent[["cic-error"]]))
  })
}
