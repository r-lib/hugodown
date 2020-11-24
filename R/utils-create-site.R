# Helpers -----------------------------------------------------------------

line_find <- function(x, pattern, fixed = FALSE) {
  ignore <- grep(pattern, x, fixed = fixed)
  if (length(ignore) != 1) {
    abort(paste0("Found ", length(ignore), " matching lines"))
  }
  ignore
}
line_replace <- function(x, pattern, replacement, fixed = FALSE) {
  x[line_find(x, pattern, fixed = fixed)] <- replacement
  x
}
line_insert_after <- function(x, pattern, lines) {
  n <- length(x)
  i <- line_find(x, pattern)
  c(x[1:i], lines, x[(i + 1):n])
}

dir_copy_contents <- function(path, new_path) {
  for (path in dir_ls(path)) {
    if (is_file(path)) {
      file_copy(path, path(new_path, path_file(path)))
    } else {
      dir_copy(path, path(new_path, path_file(path)))
    }
  }
}

# Replace after https://github.com/r-lib/usethis/issues/1153
use_rstudio_website_proj <- function(path) {
  project_name <- path_file(path_abs(path))
  rproj_file <- paste0(project_name, ".Rproj")
  new <- usethis::use_template("template.Rproj",
                               rproj_file,
                               package = "hugodown"
  )
  usethis::use_git_ignore(".Rproj.user")
}
