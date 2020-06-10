#' Manage the hugo server
#'
#' @section Hugo version:
#' hugodown will attempt to automatically use the correct version of hugo for
#' your site (prompting you to call [hugo_install()] if needed). It looks in
#' two places:
#'
#' * If `_hugodown.yml` is present, it looks for the `hugo_version` key.
#' * If `netlify.toml` is present, it looks in
#'   `context$production$environment$HUGO_VERSION`
#'
#' This means if you already use netlify, hugodown will automatically match
#' the version of hugo that you're using for deployment.
#'
#' @description
#' `hugo_start()` starts a hugo server that will automatically re-generate
#' the site whenever the input changes. You only need to execute this once
#' per session; it continues to run in the background as you work on the site.
#'
#' `hugo_stop()` kills the server. This happens automatically when you exit
#' R so you shouldn't normally need to run this.
#'
#' `hugo_browse()` opens the site in the RStudio viewer or your web browser.
#' @export
#' @param site Path to hugo site.
#' @param auto_navigate Automatically navigate to the most recently changed
#'   page?
#' @param browse Automatically preview the site after the server starts?
#' @param render_to_disk Render site to disk? The default is to serve the
#'   site from memory, but rendering to disk can be helpful for debugging.
#' @param port Port to run server on. For advanced use only.
hugo_start <- function(site = ".",
                         auto_navigate = TRUE,
                         browse = TRUE,
                         render_to_disk = FALSE,
                         port = 1313) {
  path <- site_root(site)
  hugo_stop()

  if (port_active(port)) {
    abort("`hugo` already launched elsewhere.")
  }

  message("Starting server on port ", port)
  args <- c(
    "server",
    "--port", port,
    "--buildDrafts",
    "--buildFuture",
    if (auto_navigate) "--navigateToChanged",
    if (render_to_disk) "--renderToDisk"
  )
  ps <- hugo_run_bg(path, args, stdout = "|", stderr = "2>&1")
  if (!ps$is_alive()) {
    abort(ps$read_error())
  }

  # Swallow initial text
  init <- ""
  now <- proc.time()[[3]]
  ok <- FALSE

  while (proc.time()[[3]] - now < 5) {
    ps$poll_io(250)
    init <- paste0(init, ps$read_output())

    if (grepl("Ctrl+C", init, fixed = TRUE)) {
      ok <- TRUE
      break
    }
  }

  if (!ok) {
    ps$kill()
    cat(init)
    abort("Failed to start Hugo")
  }

  # Ensure output pipe doesn't get swamped
  poll_process <- function() {
    if (!ps$is_alive()) {
      return()
    }

    out <- ps$read_output()
    if (!identical(out, "")) {
      cat(out)
    }

    later::later(delay = 1, poll_process)
  }
  poll_process()

  hugodown$server <- ps
  if (browse) {
    hugo_browse()
  }

  invisible(ps)
}

#' @rdname hugo_start
#' @export
hugo_stop <- function() {
  if (!hugo_running()) {
    return(invisible())
  }

  hugodown$server$interrupt()
  hugodown$server$poll_io(500)
  hugodown$server$kill()
  env_unbind(hugodown, "server")
  invisible()
}

#' @rdname hugo_start
#' @export
hugo_browse <- function() {
  if (is_installed("rstudioapi") && rstudioapi::hasFun("viewer")) {
    rstudioapi::viewer("http://localhost:1313")
  } else {
    utils::browseURL("http://localhost:1313")
  }
}

hugo_running <- function() {
  env_has(hugodown, "server") && hugodown$server$is_alive()
}

port_active <- function(port) {
  tryCatch({
    suppressWarnings(con <- socketConnection("127.0.0.1", port, timeout = 1))
    close(con)
    TRUE
  }, error = function(e) FALSE)
}


#' Build site
#'
#' Build static html into specified directory. Useful for debugging and some
#' deployment scenarios
#'
#' @inheritParams hugo_start
#' @param dest Destination directory. If `NULL`, the default, will build
#'   in `{site}/public`
#' @param build_drafts,build_future Should drafts and future posts be included
#'   in the built site?
#' @param clean Remove files in `public/` that don't exist in the source.
#' @export
hugo_build <- function(site = ".",
                       dest = NULL,
                       build_drafts = FALSE,
                       build_future = FALSE,
                       clean = FALSE) {
  path <- site_root(site)
  dest <- dest %||% path(path, "public")

  args <- c(
    "--destination", dest,
    if (build_drafts) "--buildDrafts",
    if (build_future) "--buildFuture",
    if (clean) "--cleanDestinationDir"
  )
  hugo_run(path, args)
  invisible()
}
