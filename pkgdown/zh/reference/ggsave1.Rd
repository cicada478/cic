\name{ggsave1}
\alias{ggsave1}
\title{保存图形并添加日期和覆盖保护}
\usage{
ggsave1(
  filename,
  plot = ggplot2::last_plot(),
  ...,
  confirm = TRUE,
  add_date = TRUE
)
}
\arguments{
\item{filename}{单个非空文件名，可包含路径。}
\item{plot}{要保存的图形，默认使用 \code{ggplot2::last_plot()}。}
\item{...}{传给 \code{\link[ggplot2:ggsave]{ggplot2::ggsave()}} 的其他参数，包括 \code{path}、\code{device}、\code{width}、\code{height}、\code{units} 和 \code{dpi}。}
\item{confirm}{逻辑值。默认 \code{TRUE}：目标已存在时，在交互式会话中提供覆盖、自动改名或取消的菜单；非交互式会话自动改名。\code{FALSE} 明确允许直接覆盖。}
\item{add_date}{是否在文件名中添加日期，默认 \code{TRUE}。}
}
\value{不可见地返回最终目标文件名；如果提供了 \code{path}，返回值包含该路径。}
\description{封装 \code{\link[ggplot2:ggsave]{ggplot2::ggsave()}} 以便保存图形。默认在扩展名前加入本地日期后缀 \verb{_YYYYMMDD}，并自动创建缺失的父目录。}
\details{文件命名、重名处理、目录创建和日志记录由 \code{\link[=out]{out()}} 完成。自动改名在扩展名前加入 \verb{_1}、\verb{_2} 等，选择第一个未占用的名称。

\code{\link[=out]{out()}} 的目录和日志选项仍然生效。\code{add_date} 和 \code{confirm} 明确决定此函数的日期与重名策略，因此 \code{cic.out.timestamp} 和 \code{cic.out.conflict} 不会覆盖这两个参数。}
\examples{
p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
output <- ggsave1(tempfile(fileext = ".pdf"), p, width = 5, height = 4)
unlink(output)
}
\seealso{\code{\link[=out]{out()}}, \code{\link[=outputs]{outputs()}}}
