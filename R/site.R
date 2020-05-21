site_root <- function(path = ".") {
  path <- path_abs(path)

  while (!identical(path, path_dir(path))) {
    if (file_exists(path(path, "config.yaml"))) {
      return(path)
    }
    if (file_exists(path(path, "config.yml"))) {
      return(path)
    }
    if (file_exists(path(path, "config.toml"))) {
      return(path)
    }
    path <- path_dir(path)
  }

  abort("Can't find 'config.yml' or 'config.toml'")
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

site_rmd <- function(path = ".", needs_render = FALSE) {
  path <- site_root(path)
  rmd <- dir_ls(path(path, "content"), recurse = TRUE, regexp = "\\.Rmd$")

  if (needs_render) {
    rmd <- rmd[vapply(rmd, rmd_needs_render, logical(1))]
  }

  rmd
}

rmd_needs_render <- function(path) {
  # Has .html, so must've been rendered by blogdown
  if (file_exists(path_ext_set(path, "html"))) {
    return(FALSE)
  }

  md_path <- path_ext_set(path, "md")
  if (!file_exists(md_path)) {
    return(TRUE)
  }

  yaml <- rmarkdown::yaml_front_matter(md_path)
  hash <- yaml$rmd_hash
  if (is.null(hash)) {
    return(FALSE)
  }

  hash != rmd_hash(path)
}

rmd_hash <- function(path) {
  digest::digest(path, file = TRUE, algo = "xxhash64")
}
