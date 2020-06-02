hugo_locate <- function() {
  path <- hugo_path()
  if (identical(path, "")) {
    abort("Can't find hugo")
  }
  path
}

hugo_path <- function() {
  path <- unname(Sys.which("hugo"))
}

hugo_version <- function() {
  out <- hugo_run("version")$stdout
  package_version(rematch2::re_match(out, "v([0-9.]+)")[[1]])
}

hugo_run <- function(args, wd = NULL, ...) {
  processx::run(hugo_locate(), args = args, wd = wd, ...)
}
