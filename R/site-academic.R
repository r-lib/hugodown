#' Create a hugo academic site
#'
#' @description
#' Create a hugo academic 4.8.0 site, configured to work well with hugodown.
#' In particular, it ensures that the following features important for R
#' users work correctly:
#'
#' * Syntax highlighting (turns off default js highlighting, renables
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
create_site_academic <- function(
                                 path = ".",
                                 open = is_interactive(),
                                 rstudio = rstudioapi::isAvailable()) {
  # Use most recent version that release was tested with
  # https://sourcethemes.com/academic/updates/v4.8.0/#breaking-changes
  hugo_locate("0.66.0")

  dir_create(path)
  usethis::ui_silence(old <- usethis::proj_set(path, force = TRUE))
  on.exit(usethis::ui_silence(usethis::proj_set(old)))

  use_rstudio_website_proj(path)

  usethis::ui_done("Downloading academic theme")
  theme_dir <- academic_download("4.8.0")

  usethis::ui_done("Copying site components")
  dir_copy_contents(path(theme_dir, "exampleSite"), path)

  usethis::ui_done("Installing academic theme")
  academic_install(path, theme_dir)

  usethis::ui_done("Patching theme for hugodown compatibility")
  academic_patch(path)

  if (open) {
    usethis::proj_activate(path)
  }
  invisible(path)
}

academic_download <- function(version = "4.8.0") {
  zip <- curl::curl_download(
    paste0("https://github.com/gcushen/hugo-academic/archive/v", version, ".zip"),
    file_temp("hugodown")
  )
  exdir <- file_temp("hugodown")
  utils::unzip(zip, exdir = exdir)
  path(exdir, paste0("hugo-academic-", version))
}

academic_install <- function(path, theme_dir) {
  theme_path <- dir_create(path(path, "themes", "academic"))
  dir_copy_contents(theme_dir, theme_path)
  dir_delete(path(theme_path, "exampleSite"))
}

# Patch existing theme ----------------------------------------------------

academic_patch <- function(path) {
  config_path <- file_move(path(path, "config", "_default", "config.toml"), path)
  academic_patch_config(config_path)
  academic_patch_params(path(path, "config", "_default", "params.toml"))
  academic_write_hugodown(path)

  # Create Rmd post archetype
  # Must modify template because site archetype is _unioned_ with template
  post_archetype <- path(path, "themes", "academic", "archetypes", "post")
  file_move(path(post_archetype, "index.md"), path(post_archetype, "index.Rmd"))
  academic_patch_post_archetype(path(post_archetype, "index.Rmd"))

  # Patch <head>
  academic_write_custom_head(path)

  usethis::use_git_ignore(c("resources", "public"))
  file_copy(path_package("hugodown", "academic", "README.md"), path)
  file_copy(path_package("hugodown", "academic", "index.Rmd"), path)

  # Can we open config files for editing in new session? Or should we have
  # edit_config()
  if (open) {
    usethis::proj_activate(path)
  }
}

academic_patch_config <- function(path) {
  lines <- brio::read_lines(path)

  # Ignore knitr intermediates
  knitr_ignore <- "ignoreFiles = ['\\.Rmd$', '_files$', '_cache$', '\\.knit\\.md$', '\\.utf8\\.md$']"
  lines <- line_replace(lines, "^ignoreFiles", knitr_ignore)

  # Use goldmark syntax higlighting (change in params.toml suppresses highlight.js)
  lines <- line_replace(lines, "    codeFences = false", "    codeFences = true")

  # Use highlight classes
  lines <- line_insert_after(lines, "^ignoreFiles", "pygmentsUseClasses = true")

  brio::write_lines(lines, path)
}

academic_patch_params <- function(path) {
  lines <- brio::read_lines(path)

  # Turn math on & js highlighting off
  lines <- line_replace(lines, "math = false", "math = true")
  lines <- line_replace(lines, "highlight = true", "highlight = false")

  brio::write_lines(lines, path)
}

academic_write_hugodown <- function(path) {
  opts <- list(
    hugo_version = "0.66.0"
  )
  yaml::write_yaml(opts, path(path, "_hugodown.yaml"))
}

academic_patch_post_archetype <- function(path) {
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
  lines <- line_replace(lines, 'lastmod: {{ .Date }}', 'lastmod: {{ date }}', fixed = TRUE)

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

# this is a modified version of usethis::use_rstudio() that
# doesn't assume the user is creating a package
use_rstudio_website_proj <- function(path, line_ending = c("posix", "windows")) {
  line_ending <- arg_match(line_ending)
  line_ending <- c(posix = "Posix", windows = "Windows")[[line_ending]]
  project_name <- basename(normalizePath(path))
  rproj_file <- paste0(project_name, ".Rproj")
  new <- usethis::use_template("template.Rproj",
                               rproj_file,
                               data = list(line_ending = line_ending),
                               package = "hugodown")
  usethis::use_git_ignore(".Rproj.user")
}


