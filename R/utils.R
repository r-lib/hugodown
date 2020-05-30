
file_mtime <- function(path) {
  file_info(path)$change_time
}

port_active <- function(port) {
  tryCatch({
    suppressWarnings(con <- socketConnection("127.0.0.1", port, timeout = 1))
    close(con)
    TRUE
  }, error = function(e) FALSE)
}


active_file <- function(ext = NULL) {
  if (!rstudioapi::isAvailable()) {
    abort("Must supply `path` outside of RSuudio")
  }

  path <- rstudioapi::getSourceEditorContext()$path

  if (!is.null(ext) && path_ext(path) != ext) {
    abort(paste0("Open file must have extension (", ext, ")"))
  }

  path
}

active_site <- function() {
  site_root(active_file())
}
