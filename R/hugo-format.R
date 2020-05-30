#' Convert to Hugo-flavoured markdown
#'
#' This RMarkdown output format is designed to generate markdown that is
#' maximally compatible with Hugo. It intelligently generates a preview so
#' that you see something useful when Hugo isn't running, but it doesn't
#' get in the way of hugo's full-site preview when it is.
#'
#' @export
#' @inheritParams rmarkdown::md_document
#' @param fig_width Figure width (in inches).
#' @param fig_asp Figure aspect ratio, defaults to the golden ratio.
#' @param tidyverse_style Use tidyverse knitr conventions? This sets
#'   `collapse = TRUE`, `comment = "#>`, `fig.align = "center"`, and
#'   `out.width = "700px"`.
hugo_document <- function(fig_width = 7,
                          fig_asp = 0.618,
                          fig_retina = NULL,
                          tidyverse_style = TRUE)
                          {

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

  if (tidyverse_style) {
    knitr$opts_chunk$collapse <- TRUE
    knitr$opts_chunk$comment <- "#>"
    knitr$opts_chunk$fig.align <- "center"
    knitr$opts_chunk$out.width <- "700px"
  }

  pandoc <- rmarkdown::pandoc_options(
    to = goldmark_format(),
    args = "--wrap=none",
    ext = ".md"
  )

  input_rmd <- NULL
  pre_knit <- function(input, ...) {
    input_rmd <<- input
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
    yaml <- rmarkdown::yaml_front_matter(input_file)
    # TODO: figure out how to preserve lists in YAML metadata
    if (has_name(yaml, "tags")) {
      yaml$tags <- as.list(yaml$tags)
    }
    if (has_name(yaml, "categories")) {
      yaml$categories <- as.list(yaml$categories)
    }
    yaml$rmd_hash <- rmd_hash(input_rmd)

    if (length(knit_meta) > 0) {
      # Capture dependencies, remove duplicates, save to directory, and render
      deps <- htmltools::resolveDependencies(knit_meta)
      local <- lapply(deps, htmltools::copyDependencyToDir, outputDir = output_dir)
      local <- lapply(local, htmltools::makeDependencyRelative, output_dir)
      deps <- strsplit(htmltools::renderDependencies(local), "\n")[[1]]
      yaml$html_dependencies <- deps
    }

    meta <- yaml::as.yaml(yaml)

    body <- brio::read_lines(output_file)
    output_lines <- c("---", meta, "---", "", body)
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
  )
}

# https://github.com/rstudio/rstudio/blob/master/src/gwt/panmirror/src/editor/src/api/pandoc_format.ts#L335-L359
goldmark_format <- function() {
  paste(
    "markdown_strict",
    "pipe_tables",
    "strikeout",
    "autolink_bare_uris",
    "task_lists",
    "backtick_code_blocks",
    "definition_lists",
    "footnotes",
    "smart",
    "tex_math_dollars",
    "native_divs",
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

local_rmd <- function(path, env = parent.frame()) {
  tmp <- dir_create(file_temp())
  withr::defer(dir_delete(tmp), envir = env)

  file_copy(path, tmp)
}
