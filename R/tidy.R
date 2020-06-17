#' Various helpers for tidyverse.org and similar sites
#'
#' * `use_tidy_post()` makes a new post
#' * `use_tidy_thumbnails()` resizes thumbnails to the correct size
#' * `tidy_show_meta()` prints tags and categories used by existing posts.
#'
#' @export
#' @param slug File name of new post. Year and month will be automatically
#'   appended.
#' @inheritParams use_post
use_tidy_post <- function(slug, site = ".", open = is_interactive()) {
  check_slug(slug)

  post_slug <- paste0("blog/", tolower(slug))
  data <- list(
    pleased = tidy_pleased()
  )
  pieces <- strsplit(slug, "-")[[1]]
  if (is_installed(pieces[[1]])) {
    data$package <- pieces[[1]]
    data$version <- utils::packageVersion(pieces[[1]])
  }

  use_post(post_slug, data = data, site = site, open = open)
}

#' @rdname use_tidy_post
#' @export
#' @param path Path to blog post
use_tidy_thumbnails <- function(path = NULL) {
  if (!is_installed("magick")) {
    abort("Need to install magick package")
  }

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

#' @rdname use_tidy_post
#' @export
#' @param min Minimum number of uses
tidy_show_meta <- function(min = 1, site = ".") {
  site <- site_root(site)
  rmd <- dir_ls(path(site, "content"), recurse = TRUE, regexp = "\\.(Rmd|Rmarkdown)$")

  yaml <- lapply(rmd, rmarkdown::yaml_front_matter)

  tags <- unlist(lapply(yaml, "[[", "tags"), use.names = FALSE)
  tags_df <- as.data.frame(table(tags), responseName = "n")
  tags_df <- tags_df[tags_df$n > min, , drop = FALSE]

  cats <- unlist(lapply(yaml, "[[", "categories"), use.names = FALSE)
  cats_df <- as.data.frame(table(cats), responseName = "n")
  cats_df <- cats_df[cats_df$n > min, , drop = FALSE]

  cat_line("## Categories")
  cat_line("* ", cats_df$cats, " (", cats_df$n, ")")
  cat_line()
  cat_line("## Tags")
  cat_line("* ", tags_df$tags, " (", tags_df$n, ")")

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
  phrases <- list(
    chuffed =     c(""),
    pleased =     c("", "most", "very", "extremely", "well"),
    stoked =      c(""),
    chuffed =     c("", "very"),
    happy =       c("", "so", "very", "exceedingly"),
    thrilled =    c(""),
    delighted =   c(""),
    "tickled pink" = c("")
  )

  i <- sample(length(phrases), 1)

  word <- names(phrases)[[i]]
  modifier <- sample(phrases[[i]], 1)

  paste0(modifier, if (modifier != "") " ", word)
}

active_file <- function(ext = NULL) {
  if (!is_installed("rstudioapi") || !rstudioapi::isAvailable()) {
    abort("Must supply `path` outside of RSuudio")
  }

  path <- rstudioapi::getSourceEditorContext()$path

  if (!is.null(ext) && path_ext(path) != ext) {
    abort(paste0("Open file must have extension (", ext, ")"))
  }

  path
}

cat_line <- function(...) cat(paste0(..., "\n", collapse = ""))
