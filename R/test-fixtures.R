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
  if (hugo_path() == "") {
    testthat::skip("hugo not installed")
  }
}
