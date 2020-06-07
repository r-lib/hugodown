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

hugo_run <- function(site, args, ...) {
  path <- site_root(site)
  hugo <- hugo_locate(site_hugo_version(path))
  processx::run(hugo, args, wd = path, ...)
}

hugo_run_bg <- function(site, args, ...) {
  path <- site_root(site)
  hugo <- hugo_locate(site_hugo_version(path))
  processx::process$new(hugo, args, wd = path, ...)
}
