
file_mtime <- function(path) {
  file_info(path)$change_time
}

port_active <- function(port) {
  tryCatch({
    suppressWarnings(con <- socketConnection(port = port))
    close(con)
    TRUE
  }, error = function(e) FALSE)
}

