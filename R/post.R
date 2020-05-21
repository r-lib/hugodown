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
    author = find_name(),
    date = strftime(Sys.Date(), "%Y-%m-%d")
  )
  data <- utils::modifyList(defaults, data)

  lapply(rmds, rmd_template, data)

  invisible(dest)
}

rmd_template <- function(path, data) {
  file <- brio::read_file(path)
  out <- whisker::whisker.render(file, data)
  brio::write_lines(out, path)
}

post_tags <- function(path = ".", min = 1) {
  md <- site_rmd(path)
  yaml <- purrr::map(md, rmarkdown::yaml_front_matter)
  tags <- unlist(purrr::map(yaml, "tags"), use.names = FALSE)

  df <- as.data.frame(table(tags), responseName = "n")
  df[df$n > min, , drop = FALSE]
}

post_categories <- function(path = ".", min = 1) {
  md <- site_rmd(path)
  yaml <- purrr::map(md, rmarkdown::yaml_front_matter)
  tags <- unlist(purrr::map(yaml, "categories"), use.names = FALSE)

  df <- as.data.frame(table(tags), responseName = "n")
  df[df$n > min, , drop = FALSE]
}

# Helpers -----------------------------------------------------------------

find_name <- function() {
  getOption("usethis.full_name") %||% getOption("devtools.name") %||% "Your name"
}
