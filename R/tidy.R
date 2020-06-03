#' Various helpers for tidyverse.org and similar sites
#'
#' * `tidy_post_create()` makes a new post
#' * `tidy_thumbnails()` resizes thumbnails to the correct size
#' * `tidy_show_meta()` prints tags and categories used by existing posts.
#'
#' @export
#' @param slug File name of new post. Year and month will be automatically
#'   appended.
#' @param site Path to hugo site
tidy_post_create <- function(slug, site = ".") {
  check_slug(slug)

  post_slug <- paste0("blog/", tolower(slug))
  data <- list(
    title = unslug(slug),
    pleased = tidy_pleased()
  )
  pieces <- strsplit(slug, "-")[[1]]
  if (is_installed(pieces[[1]])) {
    data$package <- pieces[[1]]
    data$version <- utils::packageVersion(pieces[[1]])
  }

  post_create(post_slug, data = data, site = site)
}

#' @rdname tidy_post_create
#' @export
#' @param path Path to blog post
tidy_thumbnails <- function(path = NULL) {
  path <- path %||% path_dir(active_file())

  path_sq <- path(path, "thumbnail-sq.jpg")
  if (!file_exists(path_sq)) {
    abort("Can't find 'thumbnail-sq.jpg'")
  }
  path_wd <- path(path, "thumbnail-wd.jpg")
  if (!file_exists(path_wd)) {
    abort("Can't find 'thumbnail-wd.jpg'")
  }

  thumb_sq <- magick::image_read(path_sq)
  thumb_wd <- magick::image_read(path_wd)

  info_sq <- magick::image_info(thumb_sq)
  info_wd <- magick::image_info(thumb_wd)

  if (info_sq$width != info_sq$height) {
    abort("'thumb-sq.jpg' is not square")
  }
  if (info_wd$width / (info_wd$height / 200) < 1000) {
    abort("'thumb-wd.jpg' is too narrow; must be >5 wider than tall")
  }

  magick::image_write(magick::image_scale(thumb_sq, "300x300"), path_sq, quality = 90)
  magick::image_write(magick::image_scale(thumb_wd, "x200"), path_wd, quality = 90)

  invisible()
}

#' @rdname tidy_post_create
#' @export
#' @param min Minimum number of uses
tidy_show_meta <- function(min = 1, site = ".") {
  site <- site_root(site)
  rmd <- dir_ls(path(site, "content"), recurse = TRUE, regexp = "\\.(Rmd|Rmarkdown)$")

  yaml <- purrr::map(rmd, rmarkdown::yaml_front_matter)

  tags <- unlist(purrr::map(yaml, "tags"), use.names = FALSE)
  tags_df <- as.data.frame(table(tags), responseName = "n")
  tags_df <- tags_df[tags_df$n > min, , drop = FALSE]

  cats <- unlist(purrr::map(yaml, "categories"), use.names = FALSE)
  cats_df <- as.data.frame(table(cats), responseName = "n")
  cats_df <- cats_df[cats_df$n > min, , drop = FALSE]

  cli::cli_h2("Categories")
  cli::cli_li(paste0(cats_df$cats, cli::col_grey(" (", cats_df$n, ")")))
  cli::cli_end()

  cli::cli_h2("Tags")
  cli::cli_li(paste0(tags_df$tags, cli::col_grey(" (", tags_df$n, ")")))
  cli::cli_end()

  invisible()
}


# helpers -----------------------------------------------------------------

check_slug <- function(slug) {
  if (!is.character(slug) || length(slug) != 1) {
    abort("`slug` must be a single string")
  }

  if (grepl("[ ._]", slug)) {
    abort(c(
      "`slug` must not contain any spaces, `.`, or `_`",
      i = "Separate words with -"
    ))
  }
}

unslug <- function(x) {
  gsub("-", " ", x)
}

tidy_pleased <- function() {
  phrases <- tibble::tribble(
    ~word, ~modifiers,
    "chuffed",      c(""),
    "pleased",      c("", "most", "very", "extremely", "well"),
    "stoked",       c(""),
    "chuffed",      c("", "very"),
    "happy",        c("", "so", "very", "exceedingly"),
    "thrilled",     c(""),
    "delighted",    c(""),
    "tickled pink", c(""),
  )

  i <- sample(nrow(phrases), 1)

  word <- phrases$word[[i]]
  modifier <- sample(phrases$modifiers[[i]], 1)

  paste0(modifier, if (modifier != "") " ", word)
}
