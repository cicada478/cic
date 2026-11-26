\name{outputs}
\alias{outputs}
\title{查询已分配的输出路径}
\usage{
outputs(log = getOption("cic.out.dir", "."), existing = NA, n = Inf)
}
\arguments{
\item{log}{\code{.cic_outputs.csv} 日志文件或包含该文件的目录。默认使用 \code{cic.out.dir}，未设置时使用当前工作目录。已有日志必须符合 \code{\link[=out]{out()}} 写入的字段结构。}
\item{existing}{\code{NA}（默认）保留所有记录；\code{TRUE} 仅保留存在的文件；\code{FALSE} 仅保留缺失的文件。}
\item{n}{最多返回多少条最新记录。}
}
\value{按时间从新到旧排列的数据框，\code{exists} 列在查询时计算。}
\description{查询 \code{\link[=out]{out()}} 已分配的路径及目标文件是否存在。}
\details{损坏的 CSV 或不兼容的日志结构会引发包含日志路径的错误。目录中没有日志时返回空数据框。\code{exists = FALSE} 可能表示保存失败、尚未保存或文件已被删除。}
\examples{
td <- tempfile("cic-outputs-")
dir.create(td)
path <- out(file.path(td, "table.csv"), timestamp = FALSE)
write.csv(data.frame(x = 1), path, row.names = FALSE)
outputs(td)
unlink(td, recursive = TRUE)
}
\seealso{\code{\link[=out]{out()}}, \code{\link[=ggsave1]{ggsave1()}}}
