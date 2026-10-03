\name{outputs}
\alias{outputs}
\title{Inspect Paths Allocated by out}
\usage{
outputs(log = getOption("cic.out.dir", "."), existing = NA, n = Inf)
}
\arguments{
\item{log}{A \code{.cic_outputs.csv} file or a directory containing one.}
\item{existing}{Keep all records (\code{NA}), existing files
(\code{TRUE}), or missing files (\code{FALSE}).}
\item{n}{Maximum number of most recent records to return.}
}
\value{A data frame ordered newest first with a live \code{exists} column.}
\description{
Reads the allocation log written by \code{out()} and reports which allocated
outputs currently exist.
}
\examples{
td <- tempfile("cic-outputs-")
dir.create(td)
path <- out(file.path(td, "table.csv"), timestamp = FALSE)
write.csv(data.frame(x = 1), path, row.names = FALSE)
outputs(td)
unlink(td, recursive = TRUE)
}
