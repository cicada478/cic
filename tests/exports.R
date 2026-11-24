library(cic)

# Additions must not drop the output API that existed before list_edit().
expected <- c("ggsave1", "out", "outputs", "list_edit")
stopifnot(all(expected %in% getNamespaceExports("cic")))
stopifnot(all(vapply(expected, function(name)
  is.function(getExportedValue("cic", name)), logical(1))))
