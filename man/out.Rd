\name{out}
\alias{out}
\title{Create a Safe Path for an Analysis Output}
\usage{
out(path, ext = NULL, tag = NULL,
    timestamp = getOption("cic.out.timestamp", "\%Y\%m\%d"),
    conflict = getOption("cic.out.conflict", "ask"),
    dir = getOption("cic.out.dir", NULL), create_dir = TRUE,
    log = getOption("cic.out.log", TRUE))
}
\arguments{
\item{path}{A single non-empty output path.}
\item{ext}{Optional extension, with or without a leading dot.}
\item{tag}{Optional character vector of filename tags.}
\item{timestamp}{\code{FALSE} to disable it, \code{TRUE} for
\code{\%Y\%m\%d}, or a format string accepted by \code{format()}.}
\item{conflict}{One of \code{"ask"}, \code{"increment"},
\code{"error"}, or \code{"overwrite"}. In a non-interactive session,
\code{"ask"} safely falls back to \code{"increment"}.}
\item{dir}{Optional output directory; defaults to option
\code{cic.out.dir}. Relative paths are placed inside this directory;
absolute paths take precedence and are left unchanged.}
\item{create_dir}{Whether to create missing parent directories.}
\item{log}{\code{TRUE} to log beside the output, \code{FALSE} to disable
logging, or an explicit log filename.}
}
\value{Invisibly, the final output path.}
\description{
Applies timestamp, tag, directory, collision, and logging policies to a path
that can be passed to any file-writing function. It does not write the output
itself.
}
\details{
The default protective mode displays an auto-rename, overwrite, or cancel menu
in an interactive R session. In batch use it automatically selects an unused
numbered filename. Calling \code{out()} records a path allocation; use
\code{outputs()} to see whether the file was subsequently created. Allocation
is not a file lock; concurrent processes still require synchronization.
}
\examples{
out(tempfile("markers", fileext = ".csv"), log = FALSE)
out(tempfile("seurat"), ext = "rds", tag = "final", log = FALSE)
}
