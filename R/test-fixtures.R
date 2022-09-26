local_file <- function(path, env = parent.frame()) {
  tmp <- dir_create(file_temp())
  withr::defer(dir_delete(tmp), envir = env)

  file_copy(path, tmp)
}

local_render <- function(path, env = parent.frame()) {
  tmp_path <- local_file(path, env = env)
  rmarkdown::render(tmp_path, quiet = TRUE)
  out_path <- path_ext_set(tmp_path, "md")

  lines <- brio::read_lines(out_path)
  xml <- paste("<html>", paste0(lines[-(1:5)], collapse = "\n"), "</html>")

  list(
    src = path,
    dst = out_path,
    dir = path_dir(out_path),
    lines = lines,
    xml = xml2::read_html(xml)
  )
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
