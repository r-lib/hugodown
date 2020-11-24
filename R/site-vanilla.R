#' Create a hugo vanilla site
#'
#' @description
#' Create a [hugo vanilla site](https://github.com/zwbetz-gh/vanilla-bootstrap-hugo-theme),
#' configured to work well with hugodown.
#' In particular, it ensures that the following features important for R
#' users work correctly:
#'
#' * Syntax highlighting (enables
#'   default chroma, and sets up styles in `assets/chroma.css`).
#'
#' * Math
#'
#' * HTML widgets
#'
#' * Default post archetype is tweaked to create `.Rmd`
#' @param path Path to create site
#' @param open Open new site after creation?
#' @param rstudio Create RStudio project?
#' @export
create_site_vanilla <- function(
  path = ".",
  open = is_interactive(),
  rstudio = rstudioapi::isAvailable()) {
  # Use latest version
  hugo_locate("0.78.2")

  dir_create(path)
  usethis::ui_silence(old <- usethis::proj_set(path, force = TRUE))
  on.exit(usethis::ui_silence(usethis::proj_set(old)))

  use_rstudio_website_proj(path)

  usethis::ui_done("Downloading vanilla theme")
  theme_dir <- vanilla_download()

  usethis::ui_done("Copying site components")
  dir_copy_contents(path(theme_dir, "exampleSite"), path)

  usethis::ui_done("Installing vanilla theme")
  vanilla_install(path, theme_dir)

  usethis::ui_done("Patching theme for hugodown compatibility")
  vanilla_patch(path)

  if (open) {
    usethis::proj_activate(path)
  }
  invisible(path)
}

vanilla_download <- function() {
  zip <- curl::curl_download(
    "https://github.com/zwbetz-gh/vanilla-bootstrap-hugo-theme/archive/master.zip",
    file_temp("hugodown")
  )
  exdir <- file_temp("hugodown")
  utils::unzip(zip, exdir = exdir)
  path(exdir, "vanilla-bootstrap-hugo-theme-master")
}

vanilla_install <- function(path, theme_dir) {
  theme_path <- dir_create(path(path, "themes", "vanilla-bootstrap-hugo-theme"))
  dir_copy_contents(theme_dir, theme_path)
  dir_delete(path(theme_path, "exampleSite"))
}

# Patch existing theme ----------------------------------------------------

vanilla_patch <- function(path) {
  vanilla_patch_config(file.path(path, "config.yaml"))
  vanilla_write_hugodown(path)

  # Create Rmd post archetype
  # Must modify template because site archetype is _unioned_ with template
  post_archetype <- path(path, "themes", "vanilla-bootstrap-hugo-theme", "archetypes")
  dir.create(path(post_archetype, "default"))
  file_move(path(post_archetype, "default.md"), path(post_archetype, "default", "index.Rmd"))
  vanilla_patch_post_archetype(path(post_archetype, "default", "index.Rmd"))

  # Patch <head>
  vanilla_patch_head(path)

  usethis::use_git_ignore(c("resources", "public"))
  file_copy(path_package("hugodown", "vanilla", "README.md"), path)
  file_copy(path_package("hugodown", "academic", "index.Rmd"), path)
}

vanilla_patch_config <- function(path) {
  lines <- brio::read_lines(path)

  # Ignore knitr intermediates
  knitr_ignore <- "ignoreFiles: ['\\.Rmd$', '_files$', '_cache$', '\\.knit\\.md$', '\\.utf8\\.md$']"
  lines <- line_insert_after(lines, "^theme", knitr_ignore)

  # No need for GA
  lines <- line_replace(lines, "googleAnalytics: UA-123456789-1", "")

  # Use highlight classes
  lines <- line_insert_after(lines, "^ignoreFiles", "pygmentsUseClasses: true")

  brio::write_lines(lines, path)
}


vanilla_write_hugodown <- function(path) {
  opts <- list(
    hugo_version = "0.78.2"
  )
  yaml::write_yaml(opts, path(path, "_hugodown.yaml"))
}

vanilla_patch_post_archetype <- function(path) {
  lines <- brio::read_lines(path)
  lines <- c(lines[1],
             "output: hugodown::md_document",
             lines[-1]
  )
  lines <- line_replace(lines,
                        'title: "{{ replace .Name "-" " " | title }}',
                        'title: "{{ title }}"',
                        fixed = TRUE
  )
  lines <- line_replace(lines, 'date: {{ .Date }}', 'date: {{ date }}', fixed = TRUE)

  brio::write_lines(lines, path)
}

academic_write_custom_head <- function(path) {
  # hugo gen chromastyles --style=github > inst/academic/highlight-light.css
  # hugo gen chromastyles --style=dracula > inst/academic/highlight-dark.css

  dir_create(path(path, "static", "css"))
  file_copy(path_package("hugodown", "academic", "highlight-light.css"), path(path, "static", "css"))
  file_copy(path_package("hugodown", "academic", "highlight-dark.css"), path(path, "static", "css"))

  head <- path(path, "layouts", "partials", "custom_head.html")
  dir_create(path_dir(head))

  brio::write_lines(c(
    "<link rel='stylesheet' href='{{ \"css/highlight-light.css\" | relURL }}' title='hl-light'>",
    "<link rel='stylesheet' href='{{ \"css/highlight-dark.css\" | relURL }}' title='hl-dark' disabled>",
    "{{ range .Params.html_dependencies }}",
    "  {{ . | safeHTML }}",
    "{{ end }}"
  ), head)
}
