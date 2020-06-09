#' Find hugo version needed for current site
#'
#' @description
#' Hugo changes rapidly, so it's important to pin your site to a specific
#' version and then deliberately update when needed. This function reports
#' which of hugo your site correctly uses.
#'
#' The primary location of this information is the `hugo_version` field
#' in `hugodown.yaml`. If that doesn't exist, we also look in `netlify.toml`.
#'
#' @seealso [hugo_install()] to install any version of hugo.
#' @inheritParams hugo_start
#' @export
hugo_version <- function(site = ".") {
  site <- site_root(site)

  config <- site_config(site)
  if (!is.null(config$hugo_version)) {
    return(config$hugo_version)
  }

  netlify <- path(site, "netlify.toml")
  if (file_exists(netlify)) {
    toml <- RcppTOML::parseTOML(netlify)
    # First look in production
    version <- toml$context$production$environment$HUGO_VERSION
    if (!is.null(version)) {
      return(version)
    }

    # Then in all
    version <- toml$build$environment$HUGO_VERSION
    if (!is.null(version)) {
      return(version)
    }
  }

  warn("Couldn't find hugo version declaration; falling back to latest install")
  hugo_default_get()
}
