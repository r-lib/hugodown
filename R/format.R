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

  knit_meta <- NULL
  output_dir <- NULL
  preprocess <- function(metadata, input_file, runtime, knit_meta, files_dir, output_dir) {
    knit_meta <<- knit_meta
    output_dir <<- output_dir

    NULL
  }

  postprocess <- function(metadata, input_file, output_file, clean, verbose) {
    yaml <- rmd_yaml(input_file)
    # TODO: figure out how to preserve lists in YAML metadata
    yaml$tags <- as.list(yaml$tags)
    yaml$categories <- as.list(yaml$categories)
    yaml$rmd_hash <- digest::digest(input_file, file = TRUE, algo = "xxhash64")

    if (length(knit_meta) > 0) {
      # Capture dependencies, remove duplicates, save to directory, and render
      deps <- htmltools::resolveDependencies(knit_meta)
      local <- lapply(deps, htmltools::copyDependencyToDir, outputDir = output_dir)
      local <- lapply(local, htmltools::makeDependencyRelative, output_dir)
      deps <- strsplit(htmltools::renderDependencies(local), "\n")[[1]]
      yaml$html_dependencies <- deps
    }

    meta <- yaml::as.yaml(yaml)

    input <- brio::read_lines(input_file)
    body <- input[-(1:grep("-{3,}", input)[2])]

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
    post_processor = postprocess
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
