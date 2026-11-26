\name{out}
\alias{out}
\title{为分析结果生成安全的输出路径}
\usage{
out(
  path,
  ext = NULL,
  tag = NULL,
  timestamp = getOption("cic.out.timestamp", "\%Y\%m\%d"),
  conflict = getOption("cic.out.conflict", "ask"),
  dir = getOption("cic.out.dir", NULL),
  create_dir = TRUE,
  log = getOption("cic.out.log", TRUE)
)
}
\arguments{
\item{path}{单个非空输出路径。提供 \code{ext} 时，\code{path} 作为文件名主干，不能已有不同的扩展名。}
\item{ext}{可选扩展名，可带或不带开头的点。}
\item{tag}{可选的字符向量标签，放在文件名主干与时间戳之间，以英文下划线连接。}
\item{timestamp}{\code{FALSE} 关闭时间戳，\code{TRUE} 使用 \verb{\%Y\%m\%d}，也可传入 \code{\link[base:format]{base::format()}} 支持的格式字符串。默认读取 \code{cic.out.timestamp}，未设置时使用 \verb{\%Y\%m\%d}。}
\item{conflict}{重名处理方式：默认 \code{"ask"} 在交互式会话中显示菜单，非交互式会话中退回 \code{"increment"}；\code{"increment"} 寻找未占用的编号名称；\code{"error"} 报错；\code{"overwrite"} 返回已有路径，允许后续保存函数覆盖。}
\item{dir}{可选输出目录，默认读取 \code{cic.out.dir}。相对路径放在该目录内；绝对路径优先且不被重新定位。}
\item{create_dir}{是否创建缺失的父目录。}
\item{log}{\code{TRUE} 在输出文件旁的 \code{.cic_outputs.csv} 中记录路径分配；\code{FALSE} 关闭日志；字符值指定日志文件路径。}
}
\value{不可见地返回最终输出路径。}
\description{\code{out()} 为各种保存函数统一文件命名和重名处理规则。它只分配路径，不写入目标文件内容。}
\details{
日志记录的是路径分配，保存函数在其后运行。\code{\link[=outputs]{outputs()}} 查询时检查文件是否存在，从而显示尚未完成、失败或放弃的写入。路径分配不提供文件锁；并发进程仍需自行同步。

非空日志必须依次包含 \code{time}、\code{file}、\code{requested}、\code{action}、\code{script} 五列；追加前会拒绝不兼容的日志。日志含绝对本地路径，也可能含脚本名。
}
\examples{
out(tempfile("markers", fileext = ".csv"), log = FALSE)
out(tempfile("seurat"), ext = "rds", tag = "final", log = FALSE)
}
\seealso{\code{\link[=outputs]{outputs()}}, \code{\link[=ggsave1]{ggsave1()}}}
