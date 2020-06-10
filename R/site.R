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

site_config <- function(path = ".") {
  site <- site_root(path)
  site_yaml <- path(site, "_hugodown.yaml")

  if (!file_exists(site_yaml)) {
    NULL
  } else {
    yaml::read_yaml(site_yaml)
  }
}

#' Find `.Rmd`s that need to be re-rendered.
#'
#' [md_document()] adds a hash of the input `.Rmd` in the YAML metdata of
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

hugodown_site <- function(input = ".", output_format = NULL) {

  # read config and output directory
  config <- hugo_config(input)
  output_dir <- hugo_config_str(config, "publishdir")

  list(

    # name for site (used as default name for publishing)
    name = hugo_config_str(config, "title"),

    # output directory (e.g. "public")
    output_dir = output_dir,

    # render_site callback
    render = function(input_file, output_format, envir, quiet, ...) {

      # Render the entire site
      if (is.null(input_file)) {

        hugo_build(input)
        if (!quiet)
          cat("Hugo site built:", file.path(input, output_dir))

      # render just a single file (this hook is for doing incremental
      # renders of the site based on a "Knit" in the IDE). Since
      # hugodown already handles this well w/ just delegate here to
      # rmarkdown::render.
      } else {
          rmarkdown::render(
            input = input_file,
            output_format = output_format,
            envir = envir,
            quiet = quiet,
            ...
          )
      }
    },

    # relative path to outputs that require cleaning
    clean = function() {
      files <- output_dir
      files[file.exists(file.path(input, files))]
    }
  )
}


