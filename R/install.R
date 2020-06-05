#' Install specified version of hugo
#'
#' Downloads binary from hugo releases, and installs in system wide cache.
#'
#' @param version String giving version (e.g. "0.69.0"). If omitted will
#'   default to latest release.
#' @param os Operating system, one of "Linux", "Windows", "macOS". Defaults
#'   to current operating system.
#' @param arch Architecture
#' @param extended Installed hugo-extended which also includes SCSS etc?
#' @export
#' @examples
#' \dontrun{
#' hugo_install()
#' }
hugo_install <- function(version = NULL, os = hugo_os(), arch = "64bit", extended = TRUE) {
  if (!is_installed("gh")) {
    abort("`gh` package required to install Hugo from GitHub")
  }

  message("Finding release")
  release <- hugo_release(version, os, arch, extended)

  home <- hugo_home(release$version, os, arch, extended)
  if (file.exists(home)) {
    message("hugo " , release$version, " already installed")
    return(invisible())
  }

  message("Downloading ", path_file(release$url), "...")
  temp <- tempfile()
  curl::curl_download(release$url, temp)

  message("Installing to ", path_dir(home), "...")
  switch(path_ext(release$url),
    "gz" = utils::untar(temp, exdir = home),
    "zip" = utils::unzip(temp, exdir = home)
  )

  invisible()
}

hugo_default_inc <- function(version) {
  cur <- hugo_default_get()
  if (is.na(cur) || version > cur) {
    hugo_default_set(version)
  }
}
hugo_default_path <- function() {
  path(rappdirs::user_cache_dir("hugodown"), "VERSION")
}
hugo_default_get <- function() {
  if (!file_exists(hugo_default_path())) {
    NA
  } else {
    package_version(brio::read_lines(hugo_default_path())[[1]])
  }
}
hugo_default_set <- function(version) {
  brio::write_lines(version, hugo_default_path())
}

hugo_installed <- function() {
  path_file(dir_ls(rappdirs::user_cache_dir("hugodown")))
}

hugo_home <- function(version, os = hugo_os(), arch = "64bit", extended = TRUE) {
  cache_dir <- rappdirs::user_cache_dir("hugodown")
  dir_create(cache_dir)

  hugo <- paste0(
    "hugo", if (extended) "_extended", "_",
    version, "_",
    os, "_", arch
  )
  path(cache_dir, hugo)
}

hugo_release <- function(version = NULL, os = hugo_os(), arch = "64bit", extended = TRUE) {

  json <- hugo_releases()
  if (is.null(version)) {
    i <- 1
    version <- sub("^v", "", json[[1]]$tag_name)
  } else {
    versions <- vapply(json, "[[", "tag_name", FUN.VALUE = character(1))
    versions <- sub("^v", "", versions)

    i <- which(versions == version)
    if (length(i) != 1) {
      abort(paste0("Can't find version '", version, '"'))
    }
  }

  assets <- json[[i]]$assets
  names <- vapply(assets, "[[", "name", FUN.VALUE = character(1))

  asset_name <- hugo_asset_name(version, os, arch, extended)
  asset_i <- which(asset_name == names)
  if (length(asset_i) != 1) {
    abort(paste0("Can't find release asset with name '", asset_name, "'"))
  }

  list(version = version, url = assets[[asset_i]]$browser_download_url)
}

hugo_releases <- function() {
  if (env_has(hugodown, "hugo_releases")) {
    env_get(hugodown, "hugo_releases")
  } else {
    json <- gh::gh(
      "GET /repos/:owner/:repo/releases",
      owner = "gohugoio",
      repo = "hugo",
      .limit = if (is.null(version)) 1 else Inf
    )
    env_poke(hugodown, "hugo_releases", json)
    json
  }
}

hugo_asset_name <- function(
                            version,
                            os = c("Linux", "Windows", "macOS"),
                            arch = "64bit",
                            extended = TRUE) {

  os <- arg_match(os)
  ext <- switch(os, Windows = ".zip", macOS = , Linux = ".tar.gz")

  paste0(
    "hugo", if (extended) "_extended", "_",
    version, "_",
    os, "-", arch, ext
  )
}

hugo_os <- function() {
  sysname <- tolower(Sys.info()[["sysname"]])
  switch(sysname,
    darwin = "macOS",
    linux = "Linux",
    windows = "Windows",
    abort("Unknown operating system; please set `os`")
  )
}
