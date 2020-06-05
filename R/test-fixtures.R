local_file <- function(path, env = parent.frame()) {
  tmp <- dir_create(file_temp())
  withr::defer(dir_delete(tmp), envir = env)

  file_copy(path, tmp)
}

local_dir <- function(path, env = parent.frame()) {
  tmp <- file_temp("hugodown-")
  withr::defer(dir_delete(tmp), envir = env)

  dir_copy(path, tmp)
}

skip_if_no_hugo <- function() {
  if (is.na(hugo_default_get())) {
    testthat::skip("hugo not installed")
  }
  if (hugo_default_get() < "0.72") {
    testthat::skip("need at least hugo 0.72")
  }
}
