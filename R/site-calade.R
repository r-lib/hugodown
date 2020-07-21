#' Create a hugo calade site
#'
#' @description
#' Create a hugo calade site
#'
#' @param path Path to create site
#' @param knit Should hugodown attempt to knit R markdown files?
#' @param open Open new site after creation?
#' @param rstudio Create RStudio project?
#' @export
create_site_calade <- function(
  path = ".",
  knit = TRUE,
  open = rlang::is_interactive(),
  rstudio = rstudioapi::isAvailable()
) {

  # Use the most recent version of Hugo that the theme was tested with
  # (or throw an error if it cannot be found)
  hugo_locate("0.66.0")

  # Check pandoc version. Throw error if none found, warn if below 2.1
  pandoc_check("2.1")

  # During site creation process treat project as the new site
  dir_create(path)
  usethis::ui_silence(old <- usethis::proj_set(path, force = TRUE))
  on.exit(usethis::ui_silence(usethis::proj_set(old)))

  # Create a new RStudio project and update gitignore
  usethis::use_rstudio()
  usethis::use_git_ignore(c("resources", "public"))

  # Download Hugo theme and extract to temporary folder
  usethis::ui_done("Downloading calade theme")
  exdir <- calade_download_theme()

  # Copy the example site into the new location
  usethis::ui_done("Copying site components")
  dir_copy_contents(path(exdir, "exampleSite"), path)

  # Copy the calade theme into the new location and delete
  # the unnecessary "exampleSite" subdirectory
  usethis::ui_done("Installing calade theme")
  theme_path <- dir_create(path(path, "themes", "calade"))
  dir_copy_contents(exdir, theme_path)
  dir_delete(path(theme_path, "exampleSite"))

  # Patch example site
  usethis::ui_done("Patching example site")
  calade_write_hugodown(path)
  calade_write_sentinel(path)
  calade_write_readme(path)
  calade_write_css(path)
  calade_rename_default_archetype(path)
  calade_patch_rmd_dir(path(path, "themes", "calade", "archetypes"))
  calade_patch_rmd_dir(path(path, "content"))
  calade_patch_head_custom(path)
  calade_patch_config(path)

  # Build rmd posts/projects to hugo-flavoured md and then build
  if(knit == TRUE) {
    usethis::ui_done("Knitting .Rmd files to .md")
    lapply(site_outdated(site = path), calade_build_post)
  }

  # Open in a new session if requested
  if (open) {
    usethis::proj_activate(path)
  }
}



# helpers -----------------------------------------------------------------

calade_build_post <- function(path) {
  split_path <- path_split(path)[[1]]
  local_root <- which(split_path == "content")
  tidy_path <- path_join(split_path[local_root:(length(split_path))])
  usethis::ui_line(paste("    ", tidy_path))
  suppressWarnings(rmarkdown::render(path, quiet = TRUE))
}


# Downloads and extracts the Hugo theme
calade_download_theme <- function() {
  zip <- curl::curl_download(
    "https://github.com/djnavarro/hugo-calade/archive/master.zip",
    file_temp("hugodown")
  )
  exdir <- file_temp("hugodown")
  utils::unzip(zip, exdir = exdir)
  exdir <- path(exdir, "hugo-calade-master")
  return(exdir)
}


# Convert md post archetypes to Rmd
calade_rename_default_archetype <- function(path) {
  dir_path <- path(path, "themes", "calade", "archetypes")
  new_path <- path(dir_path, "default.Rmd")
  file_move(
    path = path(dir_path, "default.md"),
    new_path = new_path
  )
}


# Patch the yaml header in an rmd file
calade_patch_rmd <- function(path) {
  lines <- brio::read_lines(path)
  lines <- c(lines[1],
             "output: hugodown::md_document",
             lines[-1]
  )
  brio::write_lines(lines, path)
}


# Patch all rmd files in a folder
calade_patch_rmd_dir <- function(path) {
  rmd_files <- dir_ls(path = path, glob = "*.Rmd", recurse = TRUE)
  lapply(rmd_files, calade_patch_rmd)
}


# Writes the hugodown yaml file
calade_write_hugodown <- function(path) {
  opts <- list(hugo_version = "0.66.0")
  yaml::write_yaml(opts, path(path, "_hugodown.yaml"))
}


# Writes the readme file
calade_write_readme <- function(path) {
  file_copy(path_package("hugodown", "calade", "README.md"), path)
}


# Writes the sentinel file
calade_write_sentinel <- function(path) {
  file_copy(path_package("hugodown", "calade", "index.Rmd"), path)
}


# Copies the highlight.css style file across
calade_write_css <- function(path) {
  dir_create(path(path, "static", "css"))
  file_copy(
    path = path_package("hugodown", "calade", "highlight.css"),
    new_path = path(path, "static", "css")
  )
}


# Inserts link to highlight.css file in head_custom.html
calade_patch_head_custom <- function(path) {

  # (is this necessary?)
  head <- path(path, "layouts", "partials", "head_custom.html")
  dir_create(path_dir(head))

  # append to file
  lines <- brio::read_lines(head)
  brio::write_lines(c(
    lines,
    "",
    "<!-- css for syntax highlighting -->",
    "<link rel='stylesheet' href='{{ \"css/highlight.css\" | relURL }}' title='hl'>",
    "{{ range .Params.html_dependencies }}",
    "  {{ . | safeHTML }}",
    "{{ end }}"
  ), head)
}


# Patches the config.toml file for the example site. Specifically, the
# config must allow the markdown renderer to pass raw html. Also needs to
# specify the publishDir
calade_patch_config <- function(path) {

  config <- path(path, "config.toml")
  lines <- brio::read_lines(config)

  # append to existing
  brio::write_lines(c(
    lines,
    '',
    '',
    '# A hugodown site requires that Hugo be explicitly',
    '# told how to handle markup. Because hugodown generates',
    '# the raw HTML for R code chunks, the "unsafe = true"',
    '# setting is required, or else Hugo will not allow the',
    '# raw HTML to be passed from the .md file to the .html',
    '# file. See:',
    '# https://gohugo.io/getting-started/configuration-markup',
    '[markup]',
    '  defaultMarkdownHandler = "goldmark"',
    '  [markup.goldmark]',
    '    [markup.goldmark.renderer]',
    '      unsafe = true',
    ''
  ), config)
}


# Throws error if pandoc is not installed, and warns if pandoc version
# is too low (needed to ensure calade example site pages knit to md)
pandoc_check <- function(version = NULL) {

  # stop if no pandoc
  if(!rmarkdown::pandoc_available()) {
    stop("Could not find a pandoc installation", call. = FALSE)
  }

  # return early if no pandoc version check is required
  if(is.null(version)) {
    return(invisible(NULL))
  }

  # throw warning if pandoc versions too low (preferred to error)
  inst_version <- rmarkdown::pandoc_version()
  version <- as.numeric_version(version)
  if(inst_version < version) {
    warning("Installation of pandoc is version ", inst_version, ". Calade site may fail to build for pandoc versions below ", version)
  }

}

