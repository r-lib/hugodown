site_config <- function(path) {
  config <- path(path, "config.yml")
  if (!file_exists(config)) {
    abort("Can't find 'config.yml'")
  }

  yaml::read_yaml(config)
}

site_check <- function(path) {
  config <- site_config(path)

  if (!identical(config$markup$defaultMarkdownHandler, "goldmark")) {
    abort("`markup.defaultMarkdownHandler` must be goldmark")
  }

  invisible()
}

site_rmd <- function(path, hours = NULL, needs_rebuild = FALSE) {
  rmd <- dir_ls(path(path, "content"), recurse = TRUE, regexp = "\\.(Rmd|Rmarkdown)$")

  if (!is.null(hours)) {
    recent <- file_mtime(rmd) > (Sys.time() - hours * 3600)
    rmd <- rmd[recent]
  }

  if (needs_rebuild) {
    out <- rmd_output(rmd)

    outdated <- file_mtime(out) < file_mtime(rmd)
    rmd <- rmd[is.na(outdated) | outdated]
  }

  rmd
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
