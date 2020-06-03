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
  loc <- regexpr("v([0-9.]+)", out)
  version <- gsub("v", "", regmatches(out, loc))
  package_version(version)
}

hugo_run <- function(args, wd = NULL, ...) {
  processx::run(hugo_locate(), args = args, wd = wd, ...)
}
