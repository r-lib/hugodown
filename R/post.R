post_create <- function(slug, date = Sys.Date()) {
  check_slug(slug)

  post_slug <- paste0(strftime(Sys.Date(), "%Y-%m"), "-", tolower(slug))
  post_dir <- path("content", "blog", post_slug)
  dir_create(post_dir)

  data <- list(
    author = find_name(),
    date = strftime(date, "%Y-%m-%d"),
    title = unslug(slug)
  )
  usethis::use_template(
    "post.Rmd",
    package = "hugodown",
    save_as = path(post_dir, "index.Rmd"),
    open = TRUE
  )
  invisible(TRUE)
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

check_slug <- function(slug) {
  if (!is.character(slug) || length(slug) != 1) {
    abort("`slug` must be a single string")
  }

  if (grepl(" ", slug)) {
    abort(c(
      "`slug` must not contain any spaces",
      i = "Separate words with -"
    ))
  }
}

unslug <- function(x) {
  gsub("-", " ", x)
}

find_name <- function() {
  getOption("usethis.full_name") %||% getOption("devtools.name") %||% "Your name"
}
