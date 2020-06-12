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

hugo_run <- function(site, args, config = NULL, ...) {
  if (length(config) > 0) {
    names(config) <- paste0("HUGO_", toupper(names(config)))
  }

  path <- site_root(site)
  hugo <- hugo_locate(hugo_version(path))
  processx::run(hugo, args, wd = path, env = config, ...)
}

hugo_run_bg <- function(site, args, ...) {
  path <- site_root(site)
  hugo <- hugo_locate(hugo_version(path))
  processx::process$new(hugo, args, wd = path, ...)
}

hugo_config <- function(site = ".", override = NULL) {
  result <- hugo_run(site, "config", config = override)
  if (result$status != 0) {
    abort(paste0("Error running hugo config: ", result$stderr))
  }

  lines <- strsplit(result$stdout, "\n", fixed = TRUE)[[1]]
  vars <- regexec("^([A-Za-z0-9_]+)\\s*=\\s*([^\n]+)$", lines)
  matches <- regmatches(lines, vars)

  config <- lapply(matches, `[[`, 3)
  names(config) <- lapply(matches, `[[`, 2)
  config
}

hugo_config_str <- function(config, key) {
  value <- config[[tolower(key)]]
  sub("^\"?(.*?)\"?$", "\\1", value)
}

hugo_config_bool <- function(config, key) {
  value <- config[[tolower(key)]]
  value == "true"
}

hugo_config_int <- function(config, key) {
  value <- config[[tolower(key)]]
  as.integer(value)
}

