# 文档维护与发布

## 文档各自负责什么

- `README.md` 与 `inst/doc/README.en.md`：定位、安装、按任务索引、最小示例和关键限制。
- `R/*.R` 的 roxygen 注释：参数、默认值、返回值和边界条件的唯一维护源；生成 `man/*.Rd` 与 `NAMESPACE`，不要分别手改两份。
- `vignettes/safe-outputs.Rmd`：输出路径、冲突处理、日志、绘图保存。
- `vignettes/list-editor.Rmd`：单列与多列、窗口模式、排序、CSV、取消和重新编辑。
- `NEWS.md` 与 `inst/doc/NEWS.en.md`：逐版本变更；GitHub Release 使用 `releases/` 下对应的中英双语草稿，发布前核对验证结果。
- `_pkgdown.yml` 与 `pkgdown/index.md`：网站导航和中文首页。
- `pkgdown/en/`：完整英文首页和教程；`pkgdown/zh/reference/`：中文函数参考翻译。英文函数参考仍来自 `man/*.Rd`。修改参数时同时更新翻译；构建会校验中英文用法签名一致。
- `scripts/build-languages.R`：在临时目录分别构建中文站与 `/en/` 英文站；各自拥有独立搜索索引。中文教程取自现有 vignette 的中文部分；两种语言共用原包代码。`scripts/localize-site.R` 为每页生成静态的对应语言链接，并补齐模板翻译。

## 本地检查

安装开发依赖 `roxygen2`、`pkgdown`、`knitr`、`rmarkdown`，并确保 Pandoc 可用。RStudio 用户可在其 R 会话中运行；独立 Rscript 可设置 `RSTUDIO_PANDOC` 为 Pandoc 所在目录。

```r
roxygen2::roxygenise(roclets = c("rd", "namespace"))
```

```sh
Rscript scripts/build-docs.R
Rscript scripts/check-site.R docs/dev
node tests/editor-js.cjs
R CMD build .
R CMD check --no-manual cic_VERSION.tar.gz
```

默认网站输出是 `docs/dev/index.html`，带开发版标识并禁止搜索引擎索引。教程的普通 R 示例会执行；交互式窗口示例不会在构建过程中启动。构建成功不等于窗口交互已经人工验证。

## 稳定版与开发版

- `main`、PR 和默认手动 workflow 只构建开发预览，上传 Actions artifact，不部署 Pages。
- 正式仓库 `cicada478/cic` 发布非 prerelease、非 draft 的 Release，且标签等于 `v` 加 `DESCRIPTION` 版本时，才可构建稳定网站。
- 只有 GitHub API 判定为 latest 的正式 Release 可部署；重新发布旧版本不会覆盖当前稳定网站。部署前再次检查。
- 稳定文档从 Release 标签检出；构建后的 HTML 通过 Pages artifact 部署，源码中不提交 `docs/`。
- `_pkgdown.yml` 默认强制开发模式，避免三段式的未发布版本号被误当成稳定版；发布工作流显式切换到 release 模式。

纯文档修订可从 `main` 手动运行 Documentation，勾选 `refresh_stable_docs`。工作流读取最新正式 Release，要求 `DESCRIPTION`、`NAMESPACE`、`R/` 和 `inst/list-edit/` 与该标签完全一致，且版本号匹配，再构建和部署文档；部署前再次核对 latest。此流程不创建版本、不移动标签，也不替换 Release 或源码包。包含代码变更时必须通过新版本发布流程。

中文站保留根网址，英文站位于 `/en/`。语言入口只出现在全站顶栏，切换到对应页面；正文不重复放置切换链接。中文说明可保留函数名、参数值、编辑器按钮原文和原始许可证/引用信息。英文站应包含与中文站对应的完整教程、参考与更新记录。检查脚本验证页面配对、切换链接、语言标记、搜索索引及英文正文中意外混入的中文。

Pages 使用 GitHub Actions，`github-pages` environment 允许正式发布标签和 `main` 的文档修订部署。中文站为 `https://cicada478.github.io/cic/`，英文站为 `https://cicada478.github.io/cic/en/`；上线结果以实际部署核验为准。

## 从旧工作副本迁移

如果本地副本的 remote 仍指向 `cic-legacy`，请先克隆正式 `cic` 仓库，再应用并审查源文件改动；不要合并两段无关历史或覆盖正式仓库。v0.4.1 已基于正式 0.3.1 历史准备，保留原有输出 API。早期 legacy 本地构建遗漏输出函数的问题不列为相对正式 0.3.1 的新修复。

旧工作目录中的 `read_csv_gz_sparse_v*.R` 是独立脚本，不属于四个公开 API。它们不纳入本次版本；`.Rbuildignore` 也排除这些文件，避免本地额外脚本误入源码包。

列表编辑功能及其参数、窗口和文档改进统一作为 0.4.1，不把开发过程中的本地迭代拆成多个发布版本。发布前同步 README、DESCRIPTION、NEWS 与 Release 说明，并完成包检查及交互式窗口人工验收。

## 私有暂存验证

正式仓库 `cicada478/cic` 保持公开；`cicada478/cic-staging` 用于私有候选验证。先在正式历史上准备候选，运行本地检查，再只上传候选分支到私有仓库。从暂存仓库重新克隆、核对提交和检查结果，记录源码包 SHA-256。获得用户对该具体候选的正式发布确认后，才更新公开仓库、标签和 Release；不得在确认前向公开仓库上传候选分支、PR 或 Release 草稿。
