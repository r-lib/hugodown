#' Manage the hugo server
#'
#' @description
#' `server_start()` starts a hugo server that will automatically re-generate
#' the site whenever the input changes. You only need to execute this once
#' per session; it continues to run in the background as you work on the site.
#'
#' `server_stop()` kills the server. This happens automatically when you exit
#' R so you shouldn't normally need to run this.
#'
#' `server_browse()` opens the site in the RStudio viewer or your web browser.
#' @export
#' @param site Path to hugo site.
#' @param auto_navigate Automatically navigate to the most recently changed
#'   page?
#' @param browse Automatically preview the site after the server starts?
#' @param render_to_disk Render site to disk? The default is to serve the
#'   site from memory, but rendering to disk can be helpful for debugging.
server_start <- function(site = ".",
                         auto_navigate = TRUE,
                         browse = TRUE,
                         render_to_disk = FALSE) {
  path <- site_root(site)
  server_stop()

  if (port_active(1313)) {
    abort("`hugo` already launched elsewhere.")
  }

  port <- 1313L
  args <- c(
    "server",
    "--port", port,
    "--buildDrafts",
    "--buildFuture",
    if (auto_navigate) "--navigateToChanged",
    if (render_to_disk) "--renderToDisk"
  )

  message("Starting server on port ", port)
  ps <- processx::process$new(
    hugo_locate(),
    args,
    wd = path,
    stdout = "|",
    stderr = "2>&1",
  )
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
    abort("Failed to start blogdown")
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
    server_browse()
  }

  invisible(ps)
}

#' @rdname server_start
#' @export
server_stop <- function() {
  if (!server_running()) {
    return(invisible())
  }

  hugodown$server$interrupt()
  hugodown$server$poll_io(500)
  hugodown$server$kill()
  env_unbind(hugodown, "server")
  invisible()
}

#' @rdname server_start
#' @export
server_browse <- function() {
  if (is_installed("rstudioapi") && rstudioapi::hasFun("viewer")) {
    rstudioapi::viewer("http://localhost:1313")
  } else {
    utils::browseURL("http://localhost:1313")
  }
}

server_running <- function() {
  env_has(hugodown, "server") && hugodown$server$is_alive()
}

port_active <- function(port) {
  tryCatch({
    suppressWarnings(con <- socketConnection("127.0.0.1", port, timeout = 1))
    close(con)
    TRUE
  }, error = function(e) FALSE)
}
