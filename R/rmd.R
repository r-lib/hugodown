rmd_build <- function(path, config = list(), quiet = FALSE) {
  if (!quiet) {
    cli::cat_rule(paste0("Rebuilding ", path))
  }

  format <- rmd_format(path, config)

  # Knit .Rmd to .md
  out <- callr::r(
    function(...) rmarkdown::render(...),
      args = list(
      input = path,
      output_format = format,
      clean = FALSE,
      run_pandoc = FALSE,
      quiet = quiet
    ),
    show = TRUE,
    spinner = FALSE
  )

  base <- path_dir(path)
  knit_path <- path(base, out)
  pandoc_path <- path_ext_set(path_ext_remove(knit_path), "md")
  ints <- path(base, setdiff(attr(out, "intermediates"), out))
  ints <- ints[file_exists(ints)]

  on.exit(file_delete(ints), add = TRUE)
  on.exit(file_delete(knit_path), add = TRUE)

  # Standardise .md to GFM
  rmarkdown::pandoc_convert(
    input = path_abs(knit_path),
    output = path_rel(pandoc_path, base),
    from = format$pandoc$from,
    to = goldmark_format()
  )

  # Capture dependencies, remove duplicates, save to directory, and render
  deps <- attr(out, "knit_meta")
  deps <- htmltools::resolveDependencies(deps)
  local <- lapply(deps, htmltools::copyDependencyToDir, outputDir = base)
  local <- lapply(local, htmltools::makeDependencyRelative, base)

  yaml <- rmd_yaml(path)
  if (length(local) > 0) {
    deps <- strsplit(htmltools::renderDependencies(local), "\n")[[1]]
    yaml$html_dependencies <- deps
  }
  yaml$rmd_hash <- digest::digest(path, file = TRUE, algo = "xxhash64")

  meta <- yaml::as.yaml(yaml)
  output_lines <- c("---", meta, "---", "", brio::read_lines(pandoc_path))
  brio::write_lines(output_lines, pandoc_path)

  if (!port_active(1313)) {
    temp <- file_temp(ext = "html")
    rmarkdown::pandoc_convert(
      input = pandoc_path,
      output = temp,
      from = goldmark_format(),
      to = "html"
    )
    message("\nOutput created: ", temp)
  }

  pandoc_path
}

local_rmd <- function(path, env = parent.frame()) {
  tmp <- dir_create(file_temp())
  withr::defer(dir_delete(tmp), envir = env)

  file_copy(path, tmp)
}

rmd_format <- function(path, config = list()) {
  knitr <- rmarkdown::knitr_options_html(7, 5, fig_retina = NULL, keep_md = TRUE)
  knitr$opts_chunk <- utils::modifyList(knitr$opts_chunk, config$knitr %||% list())
  knitr$opts_chunk$fig.path <- "figs/"

  # Need to use html here to prevent html widgets being turned into screenshots
  # But this part of the output_format is never actually used because we set
  # run_pandoc = FALSE
  pandoc <- rmarkdown::pandoc_options("html")

  rmarkdown::output_format(knitr, pandoc)
}

rmd_yaml <- function(path) {
  rmarkdown::yaml_front_matter(path)
}

rmd_output <- function(path) {
  ext_exists <- function(path, ext) file_exists(path_ext_set(path, ext))

  out_ext <- rep(NA, length(path))

  # In blogdown, Rmd's are converted to html and Rmarkdown to markdown
  # most hugodown sites will have started as blogdown, so we don't want to
  # touch existing directories
  has_html <- ext_exists(path, "html")
  out_ext[is.na(out_ext) & has_html] <- "html"

  has_markdown <- ext_exists(path, "markdown")
  out_ext[is.na(out_ext) & has_markdown] <- "markdown"

  # In hugodown, everything converted to .md
  out_ext[is.na(out_ext)] <- "md"

  path_ext_set(path, out_ext)
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
    sep = "+"
  )
}
