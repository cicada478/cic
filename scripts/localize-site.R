# Resolve each language link at build time, including without JavaScript.
localize_site <- function(root, base_url) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  files <- list.files(root, "\\.html$", recursive = TRUE, full.names = TRUE)
  for (file in files) {
    relative <- substring(file, nchar(root) + 2L)
    english <- startsWith(relative, "en/")
    page <- if (english) substring(relative, 4L) else relative
    depth <- length(strsplit(page, "/", fixed = TRUE)[[1L]]) - 1L
    other <- paste0(strrep("../", depth + as.integer(english)),
                    if (english) "" else "en/", page)
    doc <- xml2::read_html(file)
    xml2::xml_set_attr(xml2::xml_find_first(doc, "//html"), "lang", if (english) "en" else "zh-CN")
    switch <- xml2::xml_find_all(doc, "//nav//a[contains(@href, 'language.html') or contains(@class, 'cic-language-switch')]")
    if (length(switch) != 1L) stop("Expected one language switch in ", file)
    xml2::xml_set_attr(switch, "href", other)
    xml2::xml_set_attr(switch, "class", "nav-link cic-language-switch")
    xml2::xml_set_attr(switch, "hreflang", if (english) "zh-CN" else "en")
    xml2::xml_set_attr(switch, "lang", if (english) "zh-CN" else "en")
    xml2::xml_set_attr(switch, "aria-label", if (english) "切换到简体中文" else "Switch to English")
    if (!english) {
      # Fill gaps in pkgdown's own Chinese UI catalogue, without translating code,
      # licence terms or the package's bibliographic title.
      labels <- c("Usage" = "用法", "Package index" = "函数索引",
                  "Citation" = "引用", "Authors and Citation" = "作者与引用",
                  "Authors" = "作者", "Citing cic" = "引用 cic", "Full license" = "许可证全文",
                  "Site navigation" = "站点导航", "Search site" = "搜索本站",
                  "On this page" = "本页目录", "On this page:" = "本页目录：",
                  "Search for" = "搜索", "Copy to clipboard" = "复制到剪贴板",
                  "Page not found (404)" = "页面不存在（404）")
      for (node in xml2::xml_find_all(doc, "//body//text()[not(ancestor::script or ancestor::style or ancestor::pre or ancestor::code)]")) {
        key <- trimws(xml2::xml_text(node))
        if (key %in% names(labels)) xml2::xml_set_text(node, labels[[key]])
      }
      for (attribute in c("aria-label", "title", "placeholder")) {
        for (node in xml2::xml_find_all(doc, paste0("//*[@", attribute, "]"))) {
          key <- xml2::xml_attr(node, attribute)
          if (key %in% names(labels)) xml2::xml_set_attr(node, attribute, labels[[key]])
        }
      }
      title <- xml2::xml_find_first(doc, "//title")
      xml2::xml_set_text(title, sub("Authors and Citation", "作者与引用", xml2::xml_text(title), fixed = TRUE))
    }
    if (page == "LICENSE.html") {
      heading <- if (english) "MIT License" else "MIT 许可证"
      xml2::xml_set_text(xml2::xml_find_first(doc, "//main//h1"), heading)
      xml2::xml_set_text(xml2::xml_find_first(doc, "//title"), paste0(heading, " • cic"))
    }
    head <- xml2::xml_find_first(doc, "//head")
    # Some pkgdown versions request legacy favicon sizes that the favicon
    # service no longer generates. Link only the generated, present assets.
    icons <- xml2::xml_find_all(head, "link[@rel='icon' or @rel='apple-touch-icon']")
    for (icon in icons) {
      if (!file.exists(file.path(dirname(file), xml2::xml_attr(icon, "href")))) xml2::xml_remove(icon)
    }
    if (!length(xml2::xml_find_all(head, "link[@rel='icon']"))) {
      icon_path <- paste0(strrep("../", depth), "favicon-96x96.png")
      if (file.exists(file.path(dirname(file), icon_path))) {
        xml2::xml_add_child(head, "link", rel = "icon", type = "image/png", sizes = "96x96", href = icon_path)
      }
    }
    xml2::xml_remove(xml2::xml_find_all(head, "link[@rel='alternate']|style[@id='cic-language-style']"))
    xml2::xml_add_child(head, "link", rel = "alternate", hreflang = "zh-CN", href = paste0(base_url, "/", page))
    xml2::xml_add_child(head, "link", rel = "alternate", hreflang = "en", href = paste0(base_url, "/en/", page))
    xml2::xml_add_child(head, "style", ".cic-language-switch { white-space: nowrap; min-height: 44px; display: inline-flex; align-items: center; } .cic-language-switch:focus-visible { outline: 2px solid currentColor; outline-offset: 2px; }", id = "cic-language-style")
    xml2::write_html(doc, file)
  }
}
