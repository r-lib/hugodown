hugo_locate <- function() {
  path <- unname(Sys.which("hugo"))
  if (identical(path, "")) {
    abort("Can't find hugo")
  }
  path
}

hugo_version <- function() {
  out <- hugo_run("version")$stdout
  package_version(rematch2::re_match(out, "v([0-9.]+)")[[1]])
}

hugo_run <- function(args, ...) {
  processx::run(hugo_locate(), args = args, ...)
}

hugo_serve <- function(path, ...) {
  args <- c(
    "serve",
    "--buildFuture",
    "--watch",
    "--quiet"
  )
  hugo_run(args, ..., wd = path, echo = TRUE)
}
