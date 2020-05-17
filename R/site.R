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


