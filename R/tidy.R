tidy_post_create <- function(slug, site = ".") {
  check_slug(slug)

  post_slug <- paste0("blog/", strftime(Sys.Date(), "%Y-%m"), "-", tolower(slug))
  data <- list(
    title = unslug(slug),
    pleased = tidy_pleased()
  )

  pieces <- strsplit(slug, "-")[[1]]
  if (is_installed(pieces[[1]])) {
    data$package <- package
    data$version <- packageVersion(package)
  }

  post_create(post_slug, data = data, site = site)
}

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


# helpers -----------------------------------------------------------------

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

