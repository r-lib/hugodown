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
