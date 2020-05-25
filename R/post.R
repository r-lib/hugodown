#' Create a new post
#'
#' Post creation takes advantage of Hugo's
#' [archetypes](https://gohugo.io/content-management/archetypes/) or templates,
#' with an extension for `.Rmd` files. `post_create()` first calls `hugo new`
#' (which will apply go templating to `.md` files in the archetype),
#' and then uses [whisker](https://github.com/edwindj/whisker) to template
#' any `.Rmd` files.
#'
#' @param path Directory to create, like `blog/2020-my-favourite-package`.
#' @param kind Kind of archetype of use; usually automatically derived
#'   from the base directory of `path`.
#' @param data Any additional data to be used when templating `.Rmd` files.
#'   The default set `date` to today's date (in YYYY-MM-DD format), and
#'   author to your name (if set in the `usethis.full_name` option).
#' @param site Path to the hugo site.
#' @export
post_create <- function(path, kind = NULL, data = list(), site = ".") {
  site <- site_root()

  tld <- path_dir(path)
  if (!dir_exists(path(site, "content", tld))) {
    abort(paste0("Can't no '", tld, "' directory in 'content/'"))
  }

  dest <- path(site, "content", path)
  if (file_exists(dest)) {
    abort(paste0("`path` already exists"))
  }

  hugo_run(c(
    "new", path,
    if (!is.null(kind)) c("--kind", kind)
  ))

  rmds <- dir_ls(dest, glob = "*.Rmd")
  defaults <- list(
    slug = path_file(path),
    author = find_name(),
    date = strftime(Sys.Date(), "%Y-%m-%d")
  )
  data <- utils::modifyList(defaults, data)

  lapply(rmds, rmd_template, data)

  index <- dir_ls(dest, pattern = "index")
  usethis::edit_file(index)

  invisible(dest)
}

rmd_template <- function(path, data) {
  file <- brio::read_file(path)
  out <- whisker::whisker.render(file, data)
  brio::write_lines(out, path)
}


# Helpers -----------------------------------------------------------------

find_name <- function() {
  getOption("usethis.full_name") %||% getOption("devtools.name") %||% "Your name"
}
