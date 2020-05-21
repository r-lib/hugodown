site_create <- function(path, theme = "jrutheiser/hugo-lithium-theme") {
  if (file_exists(path)) {
    abort("`path` already exists")
  }

  message("Initialising site")
  hugo_run(c("new", "site", path_real(path)))

  # Delete default archetype since it's used instead of theme archetypes
  # https://gohugo.io/content-management/archetypes/#what-are-archetypes
  file_delete(path(path, "archetypes", "default.md"))

  message("Installing theme")
  site_add_theme(theme, site = path)

  usethis::create_project(path)

  invisible(path)
}

site_add_theme <- function(theme, site = ".") {
  if (!grepl("^http", theme)) {
    theme <- paste0("https://github.com/", theme, "/archive/master.zip")
  }

  zip <- file_temp()
  utils::download.file(theme, zip, quiet = TRUE)

  theme_dir <- file_temp()
  utils::unzip(zip, exdir = theme_dir)
  if (length(dir_ls(theme_dir)) == 1) {
    theme_dir <- dir_ls(theme_dir)
  }
  name <- hugo_config(theme_dir, "theme")$name
  name <- gsub("\"", "", name)

  dir_copy(theme_dir, path(path, "themes", name))

  # A bunch of extra work is needed here to pull out the exampleSite
  # from within the theme, so you have some starter content.

}

hugo_config <- function(path, config = NULL) {
  args <- c(
    "config",
    if (!is.null(config)) c("--config", config)
  )
  out <- hugo_run(args, wd = path)
  lines <- strsplit(out$stdout, "\n")[[1]]
  parsed <- rematch2::re_match(lines, "(.*?) ?[=:] (.*)")
  stats::setNames(as.list(parsed[[2]]), parsed[[1]])
}
