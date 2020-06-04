site_root <- function(path = ".") {
  path <- as.character(path_abs(path))

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

site_hugo_version <- function(site) {
  # For now, just use the default version
  hugo_default_get()
}

#' Find `.Rmd`s that need to be re-rendered.
#'
#' [hugo_document()] adds a hash of the input `.Rmd` in the YAML metdata of
#' the `.md` file that it creates. This provides a reliable way to determine
#' whether or not a `.Rmd` has been changed since the last time the `.md`
#' was rendered.
#'
#' @param site Path to hugo site.
#' @export
site_outdated <- function(site = ".") {
  site <- site_root(site)

  rmd <- dir_ls(path(site, "content"), recurse = TRUE, regexp = "\\.Rmd$")
  rmd <- rmd[vapply(rmd, rmd_needs_render, logical(1))]
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
