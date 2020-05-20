site_root <- function(path) {
  while (!identical(path, path_dir(path))) {
    path <- path_dir(path)
    if (file_exists(path(path, "config.yml"))) {
      return(path)
    }
  }

  abort("Can't find 'config.yml'")
}

site_config <- function(path) {
  config <- path(site_root(path), "config.yml")
  yaml::read_yaml(config)
}

site_check <- function(path) {
  config <- site_config(path)

  if (!identical(config$markup$defaultMarkdownHandler, "goldmark")) {
    abort("`markup.defaultMarkdownHandler` must be 'goldmark'")
  }

  if (!identical(config$markup$goldmark$renderer$unsafe, TRUE)) {
    abort("`markup.goldmark.rendered.unsafe` must be 'true'")
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


