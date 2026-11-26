\name{list_edit}
\alias{list_edit}
\title{交互式创建或编辑独立的字符列表}
\usage{
list_edit(
  x = NULL,
  output = c("auto", "list", "vector"),
  file = NULL,
  viewer = c("auto", "window", "dialog", "browser")
)
}
\arguments{
\item{x}{向量、包含简单向量的非空列表或数据框。值会转为文本。\code{NULL} 打开一个空列。\code{x} 和 \code{file} 只能提供其中一个。}
\item{output}{返回类型。默认 \code{"auto"} 根据完成时的列数决定：一列返回字符向量，多列返回命名列表，空列也计数。\code{"list"} 始终返回命名列表。\code{"vector"} 要求恰好一列并禁止新增列。}
\item{file}{可选的 UTF-8 分隔文本路径，用于替代 \code{x}。\code{\link[data.table:fread]{data.table::fread()}} 自动识别 CSV、TSV、分号等分隔符。首个非空行包含列名。\code{001}、文本 \code{NA} 和非空值两侧空格均保留为文本；支持 UTF-8 BOM。包含分隔符或双引号的内容需加引号，内部双引号写成两个双引号。不支持 Excel 或 R 二进制格式。}
\item{viewer}{窗口模式。默认 \code{"auto"} 和 \code{"window"} 在 Windows 上优先使用已有的 Edge/Chrome 独立应用窗口，否则使用默认浏览器；\code{"window"} 会提示未找到支持程序时的回退。\code{"browser"} 明确使用默认浏览器，可能打开标签页。\code{"dialog"} 需要 RStudio 和 rstudioapi，保留 RStudio 的移动和缩放限制。独立窗口支持系统移动、缩放和最大化，但不保证始终置顶。}
}
\value{由 \code{output} 决定返回字符向量或由字符向量组成的命名列表。自动模式下的单个空列返回 \code{character(0)}。取消或浏览器断开连接会引发错误，保留赋值目标的原有值。导出 CSV 不会提交 R 返回结果。}
\description{用于逐列录入、粘贴、排序与导出独立列表。操作流程参考 Dillon Hammill 的 DataEditR；编辑器由 cic 独立实现，不包含 DataEditR 源码。}
\details{
需要交互式 R 以及可选依赖 shiny 和 jsonlite。编辑会占用当前 R 会话，直到完成或取消。关闭浏览器后需等连接断开被检测到，不一定立即结束。不会自动向全局环境赋值，也不会覆盖输入文件。

各列独立。空白单元格和 R 缺失值被略去；其他空格、重复值、大小写与顺序保留。列名必须非空且唯一。向量元素的名称会被丢弃；单列标题不会保留在向量输出中。类似公式的输入仍为普通文本。不应使用独立列同步调整成对的细胞类型和颜色。

\code{Enter} 向下移动，\code{Tab} 向右并在边界换行；按住 \code{Shift} 反向移动。\code{Esc} 从单元格移到工具栏；\code{Alt + Up/Down} 调整当前项目顺序。可粘贴以制表符或换行符分隔的文本。拖动项目手柄在列内排序，拖动标题手柄移动整列，也可用箭头按钮。撤销和重做可恢复已删除的列。不支持跨列拖动。

导出 CSV 为 UTF-8 文本，较短的列用空单元格补齐。代码预览使用 \code{\link[base:dput]{base::dput()}} 生成可复现表达式，返回类型规则与完成操作一致。把表达式赋给脚本中的变量即可非交互复用；剪贴板受限时可手动使用 \code{Ctrl + C} 复制。
}
\examples{
if (interactive() && requireNamespace("shiny", quietly = TRUE) &&
    requireNamespace("jsonlite", quietly = TRUE)) {
  cell_order <- list_edit()
  markers <- list_edit(list(T_cell = c("CD3D", "CD3E")), output = "list")
  genes <- list_edit(output = "vector", viewer = "browser")
}
}
\references{工具栏和导出理念参考 \href{https://github.com/DillonHammill/DataEditR}{Dillon Hammill 的 DataEditR}。未包含其源码，DataEditR 也不是依赖。}
\seealso{\code{\link[=out]{out()}}, \code{\link[=outputs]{outputs()}}, \code{\link[=ggsave1]{ggsave1()}}}
