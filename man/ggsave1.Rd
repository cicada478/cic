\name{ggsave1}
\alias{ggsave1}
\title{Save a plot with a date suffix and overwrite protection}
\usage{
ggsave1(filename, plot = ggplot2::last_plot(), ..., confirm = TRUE,
  add_date = TRUE)
}
\arguments{
\item{filename}{A single, non-empty filename, optionally including a path.}
\item{plot}{Plot to save. Defaults to \code{ggplot2::last_plot()}.}
\item{...}{Additional arguments passed to \code{ggplot2::ggsave()}, including
\code{path}, \code{device}, \code{width}, \code{height}, \code{units}, and \code{dpi}.}
\item{confirm}{Logical. If \code{TRUE} (default), an existing destination triggers
an interactive menu offering overwrite, automatic renaming, or cancellation.
In a non-interactive session, an existing destination is automatically renamed.
Set \code{FALSE} to explicitly allow overwriting without a prompt.}
\item{add_date}{Logical. Whether to append the date; defaults to \code{TRUE}.}
}
\value{Invisibly, the final destination filename, including \code{path} if supplied.}
\description{
Wraps \code{ggplot2::ggsave()} for convenient plot export. By default, a date
suffix (\code{_YYYYMMDD}, using the local date) is inserted before the extension.
Missing parent directories are created automatically.
}
\details{
File naming, collision handling, directory creation, and output logging are
delegated to \code{out()}. Automatic renaming appends \code{_1}, \code{_2},
and so on before the extension, selecting the first unused filename.
}
\examples{
p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
output <- ggsave1(tempfile(fileext = ".pdf"), p, width = 5, height = 4)
unlink(output)
}
