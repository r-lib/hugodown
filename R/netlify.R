#' Create `netlify.toml`
#'
#' This helper creates a basic `netlify.toml` file, automatically setting the
#' hugo version to match your blog. This is needed when publishing your site
#' with [netlify](https://www.netlify.com); see `vignette("deploy")` for more
#' details.
#'
#' @export
#' @inheritParams use_post
use_netlify_toml <- function(site = ".") {
  site <- site_root(site)

  usethis::ui_done("Writing netlify.toml")
  whisker_template(
    path_package("hugodown", "templates", "netlify.toml"),
    path(site, "netlify.toml"),
    list(hugo_version = site_hugo_version(site))
  )
}
