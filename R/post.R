#' Create a new post
#'
#' Post creation takes advantage of Hugo's
#' [archetypes](https://gohugo.io/content-management/archetypes/) or templates,
#' with an extension for `.Rmd` files. `use_post()` first calls `hugo new`
#' (which will apply go templating to `.md` files in the archetype),
#' and then uses [whisker](https://github.com/edwindj/whisker) to template
#' any `.Rmd` files.
#'
#'
#' @param path Directory to create, like `blog/2020-my-favourite-package`.
#' @param kind Kind of archetype of use; usually automatically derived
#'   from the base directory of `path`.
#' @param data Any additional data to be used when templating `.Rmd` files.
#'
#'   The default data includes:
#'   * `date`: today's date (in YYYY-MM-DD format).
#'   * `author`: [whoami::fullname()].
#'   * `slug`: taken from the file name of `path`.
#' @param site Path to the hugo site.
#' @param open Open file for interactive editing?
#' @export
use_post <- function(path, kind = NULL, data = list(), site = ".", open = is_interactive()) {
  site <- site_root(site)

  tld <- path_dir(path)
  if (!dir_exists(path(site, "content", tld))) {
    abort(paste0("Can't find '", tld, "' directory in 'content/'"))
  }

  dest <- path(site, "content", path)
  if (file_exists(dest)) {
    abort(paste0("`path` already exists"))
  }

  args <- c(
    "new", path,
    if (!is.null(kind)) c("--kind", kind)
  )
  hugo_run(site, args)


  # Not a bundle
  if (!file_exists(dest)) {
    return()
  }

  rmds <- dir_ls(dest, glob = "*.Rmd")
  defaults <- list(
    slug = path_file(path),
    title = unslug(path_file(path)),
    author = whoami::fullname("Your name"),
    date = strftime(Sys.Date(), "%Y-%m-%d")
  )
  data <- utils::modifyList(defaults, data)

  lapply(rmds, function(path) whisker_template(path, path, data))

  index <- dir_ls(dest, pattern = "index")
  usethis::edit_file(index, open = open)

  invisible(dest)
}

whisker_template <- function(in_path, out_path, data) {
  file <- brio::read_file(in_path)
  out <- whisker::whisker.render(file, data)
  brio::write_lines(out, out_path)
}
