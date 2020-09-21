#' An Rmd output format that produces Hugo-flavoured markdown
#'
#' This RMarkdown output format is designed to generate markdown that is
#' maximally compatible with Hugo. It intelligently generates a preview so
#' that you see something useful when Hugo isn't running, but it doesn't
#' get in the way of hugo's full-site preview when it is.
#'
#' @section Syntax highlighting:
#'
#' `md_document()` uses a hybrid system for syntax highlighting.
#' For R code it uses [downlit](http://github.com/r-lib/downlit). For
#' other languages, it relies on Chroma, the syntax highlighter built into
#' hugo.
#'
#' @export
#' @inheritParams rmarkdown::md_document
#' @param fig_width Figure width (in inches).
#' @param fig_asp Figure aspect ratio, defaults to the golden ratio.
#' @param tidyverse_style Use tidyverse knitr conventions? This sets
#'   `collapse = TRUE`, `comment = "#>`, `fig.align = "center"`, and
#'   `out.width = "700px"`.
md_document <- function(fig_width = 7,
                        fig_asp = 0.618,
                        fig_retina = 2,
                        tidyverse_style = TRUE
                        ) {

  knitr <- rmarkdown::knitr_options_html(
    fig_height = NULL,
    fig_width = fig_width,
    fig_retina = fig_retina,
    keep_md = FALSE
  )
  knitr$opts_chunk$fig.asp <- fig_asp
  knitr$opts_chunk$fig.path <- "figs/"
  # Ensure knitr doesn't turn HTML widgets into pngs
  knitr$opts_chunk$screenshot.force <- FALSE

  knitr$knit_hooks <- knit_hooks()

  if (tidyverse_style) {
    knitr$opts_chunk$collapse <- TRUE
    knitr$opts_chunk$comment <- "#>"
    knitr$opts_chunk$fig.align <- "center"
    knitr$opts_chunk$out.width <- "700px"
  }

  pandoc <- rmarkdown::pandoc_options(
    to = goldmark_format(),
    from = paste0(rmarkdown::rmarkdown_format(), "+emoji"),
    args = "--wrap=none",
    ext = ".md"
  )

  input_rmd <- NULL
  old_options <- NULL
  old_env <- NULL

  pre_knit <- function(input, ...) {
    input_rmd <<- input
    old_options <<- options(
      cli.unicode = TRUE,
      crayon.enabled = TRUE
    )
    old_env <- set_envvar(c(RSTUDIO = 0))
  }
  on_exit <- function(...) {
    options(old_options)
    set_envvar(old_env)
  }

  hack_always_allow_html <- function(...) {
    # This truly awful hack ensures that rmarkdown doesn't tell us we're
    # producing HTML widgets
    render_env <- env_parent(parent.frame())
    render_env$front_matter$always_allow_html <- TRUE
    NULL
  }

  knit_meta <- NULL
  output_dir <- NULL
  preprocess <- function(metadata, input_file, runtime, knit_meta, files_dir, output_dir) {
    knit_meta <<- knit_meta
    output_dir <<- output_dir
    NULL
  }

  postprocess <- function(metadata, input_file, output_file, clean, verbose) {
    old_yaml <- extract_yaml(brio::read_lines(input_file))

    new_yaml <- list(rmd_hash = rmd_hash(input_rmd))
    if (length(knit_meta) > 0) {
      if (!is_installed("htmltools")) {
        abort("htmltools package required for posts that include HTML widgets")
      }

      # Capture dependencies, remove duplicates, save to directory, and render
      deps <- htmltools::resolveDependencies(knit_meta)
      local <- lapply(deps, htmltools::copyDependencyToDir, outputDir = output_dir)
      local <- lapply(local, htmltools::makeDependencyRelative, output_dir)
      deps <- strsplit(htmltools::renderDependencies(local), "\n")[[1]]
      new_yaml$html_dependencies <- deps
    }

    body <- brio::read_file(output_file)

    output_lines <- c(
      "---", old_yaml, yaml::as.yaml(new_yaml), "---",
      "",
      link_inline(body)
    )
    brio::write_lines(output_lines, output_file)

    # If server not running, and RStudio is rendering the doc, generate
    # a standalone HTML file for preview
    if (!port_active(1313) && !is.na(preview_dir())) {
      output_html <- "preview.html"
      rmarkdown::pandoc_convert(
        input = output_file,
        output = output_html,
        to = "html",
        options = preview_pandoc_args()
      )
      output_file <- file_move(output_html, preview_path())
    } else {
      output_file <- tempdir()
    }

    output_file
  }

  rmarkdown::output_format(
    knitr = knitr,
    pandoc = pandoc,
    pre_processor = preprocess,
    post_processor = postprocess,
    pre_knit = pre_knit,
    post_knit = hack_always_allow_html,
    on_exit = on_exit
  )
}

goldmark_format <- function() {
  paste(
    "markdown_strict",
    # https://github.com/rstudio/rstudio/blob/master/src/gwt/panmirror/src/editor/src/api/pandoc_format.ts#L344-L356
    "all_symbols_escapable",
    "backtick_code_blocks",
    "fenced_code_blocks",
    "space_in_atx_header",
    "intraword_underscores",
    "lists_without_preceding_blankline",
    "shortcut_reference_links",
    # https://github.com/rstudio/rstudio/blob/master/src/gwt/panmirror/src/editor/src/api/pandoc_format.ts#L380-L392
    "pipe_tables",
    "strikeout",
    "autolink_bare_uris",
    "task_lists",
    "definition_lists",
    "footnotes",
    "smart",
    "tex_math_dollars",
    # custom
    "native_divs",
    "emoji",
    sep = "+"
  )
}

preview_pandoc_args <- function() {
  template_path <- path_package(
    "rmarkdown/templates/github_document/resources/preview.html",
    package = "rmarkdown"
  )
  css_path <- path_package(
    "rmarkdown/templates/github_document/resources/github.css",
    package = "rmarkdown"
  )

  args <- c(
    "--standalone",
    "--self-contained",
    "--highlight-style", "pygments",
    "--template", template_path,
    "--email-obfuscation", "none",
    "--variable", paste0("github-markdown-css:", css_path),
    "--metadata", "pagetitle=PREVIEW"
  )
}

preview_dir <- function() {
  Sys.getenv("RMARKDOWN_PREVIEW_DIR", unset = NA)
}
preview_path <- function() {
  file_temp("preview-", preview_dir(), ext = "html")
}

extract_yaml <- function(lines) {
  delim <- grep("^---\\s*$", lines)
  if (length(delim) < 2) {
    return(character())
  }

  lines[(delim[[1]] + 1):(delim[[2]] - 1)]
}


# knitr hooks -------------------------------------------------------------

knit_hooks <- function() {
  in_code <- FALSE
  needs_code <- function(val, x, before = TRUE) {
    if (val == in_code) {
      return(x)
    }

    in_code <<- val
    if (val) {
      html <- "<pre class='chroma'><code class='language-r' data-lang='r'>"
      ws <- ""
    } else {
      html <- "</code></pre>"

      # move trailing newline after code
      if (grepl("\n$", x)) {
        x <- gsub("\n$", "", x)
        ws <- "\n"
      } else {
        ws <- ""
      }
    }

    if (before) {
      paste0(html, x, ws)
    } else {
      paste0(x, html, ws)
    }
  }

  hook_output <- function(type, x, options) {
    if (options$results == "asis") {
      needs_code(FALSE, x)
    } else {
      x <- paste0(x, "\n", collapse = "")
      x <- highlight_if_possible(x, options$engine)
      needs_code(TRUE, x)
    }
  }
  hook_source <- function(x, options) {
    x <- paste0(x, "\n", collapse = "")
    x <- highlight_if_possible(x, options$engine)
    x <- paste0(x, "\n")
    needs_code(TRUE, x)
  }
  hook_plot <- function(x, options) {
    # Repair damage done by pretending to be latex
    if (grepl("linewidth", options$out.width)) {
      width <- as.numeric(gsub("\\\\linewidth", "", options$out.width))
      options$out.width <- paste0(width * 100, "%")
    }

    x <- knitr::hook_plot_md(x, options)
    needs_code(FALSE, x)
  }

  hook_chunk <- function(x, options, ...) {
    x <- needs_code(FALSE, x, before = FALSE) # reset for next chunk
    x <- indent(x, options$indent)
    paste0("<div class='highlight'>", x, "</div>")
  }

  evaluate <- function(input, ...) {
    # Setting output format to latex ensures that asis outputs are still
    # passed to hook_output
    Encoding(input) <- "UTF-8"
    knitr::opts_knit$set(out.format = "latex")
    evaluate::evaluate(input, ...)
  }

  list(
    chunk   = hook_chunk,
    evaluate = evaluate,
    source  = hook_source,
    plot    = hook_plot,
    output  = function(x, opts) hook_output("output", x, opts),
    warning = function(x, opts) hook_output("warning", x, opts),
    error   = function(x, opts) hook_output("error", x, opts),
    message = function(x, opts) hook_output("message", x, opts)
  )
}

# if x is not valid R code, downlit::highlight will return NA
# In this case, we return x without highlighting.
highlight_if_possible <- function(x, engine) {
  if (engine != "R") {
    x
  } else {
    out <- downlit::highlight(x, pre_class = NULL)
    # replace curly operator with HTML entities
    # otherwise Hugo will treat it as a shortcode
    out <- gsub("\\{\\{", "&#123;&#123;", out)
    out <- gsub("\\}\\}", "&#125;&#125;", out)
    if (is.na(out)) {
      x
    } else {
      out
    }
  }
}


indent <- function(x, indent) {
  if (is.null(indent)) {
    return(x)
  }
  paste0(indent, gsub("\n", paste0("\n", indent), x))
}

# inline code -------------------------------------------------------------

link_inline <- function(x) {
  regexps <- c(
    "\\[[^\\]]+\\]\\([^\\)]*\\)" , # link
    "(?m)^\\s*#{1,}.*$", # heading
    "(?s)<pre.*?</pre>" # code block
  )
  danger <- paste0("(", regexps, ")", collapse = "|")

  protect_code <- function(x) gsub("`", "\u241E", x)
  restore_code <- function(x) gsub("\u241E", "`", x)

  x <- str_replace(x, danger, protect_code)
  x <- str_replace(x, "(?<!``)`([^`]+)`", function(match) {
    code <- gsub("^`|`$", "", match)
    href <- vapply(code, downlit::autolink_url, character(1))
    ifelse(is.na(href), match, paste0("[", match, "](", href, ")"))
  })
  x <- str_replace(x, danger, restore_code)
  x
}

str_replace <- function(x, pattern, fun, ...) {
  loc <- gregexpr(pattern, x, perl = TRUE)
  matches <- regmatches(x, loc)
  out <- lapply(matches, fun, ...)

  regmatches(x, loc) <- out
  x
}

#' Deprecated: please use `md_document()`
#' @export
#' @keywords internal
hugo_document <- md_document
