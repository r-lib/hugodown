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

  # Require pandoc version 2.1 or greater
  check_pandoc("2.1")

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
  yaml::write_yaml(list(hugo_version = "0.66.0"), path(path, "_hugodown.yaml"))
  file_copy(path_package("hugodown", "calade", "index.Rmd"), path)

  calade_rename_default_archetype(path)
  calade_patch_rmd_dir(path(path, "themes", "calade", "archetypes"))
  calade_patch_rmd_dir(path(path, "content"))

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
  lines <- c(lines[1], "output: hugodown::md_document", lines[-1])
  brio::write_lines(lines, path)
}

# Patch all rmd files in a folder
calade_patch_rmd_dir <- function(path) {
  rmd_files <- dir_ls(path = path, glob = "*.Rmd", recurse = TRUE)
  lapply(rmd_files, calade_patch_rmd)
}

# Throws error if pandoc is not installed, and warns if pandoc version
# is too low (needed to ensure calade example site pages knit to md)
check_pandoc <- function(version = NULL) {

  # error if no pandoc
  if(!rmarkdown::pandoc_available()) {
    abort("Could not find a pandoc installation")
  }

  # return early if no pandoc version check is required
  if(is.null(version)) {
    return(invisible(NULL))
  }

  # throws error if pandoc version too low
  inst_version <- rmarkdown::pandoc_version()
  version <- as.numeric_version(version)
  if(inst_version < version) {
    abort(
      paste0(
        "Installation of pandoc is version ", inst_version,
        ". Calade site may fail to build for pandoc versions below ", version
      )
    )
  }

}

