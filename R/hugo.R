hugo_locate <- function(version = hugo_default_get()) {
  path <- hugo_home(version)
  if (!file_exists(path)) {
    abort(c(
      paste0("hugo ", version, " not installed"),
      i = paste0("Do you need to call `hugo_install('", version, "')`?")
    ))
  }

  path(path, "hugo")
}

hugo_path <- function(version) {
  path <- unname(Sys.which("hugo"))
}

hugo_version <- function(version) {
  out <- hugo_run(version, "version")$stdout
  loc <- regexpr("v([0-9.]+)", out)
  version <- gsub("v", "", regmatches(out, loc))
  package_version(version)
}

hugo_run <- function(version, args, wd = NULL, ...) {
  processx::run(hugo_locate(version), args = args, wd = wd, ...)
}
