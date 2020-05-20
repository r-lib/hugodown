
file_mtime <- function(path) {
  file_info(path)$change_time
}

port_active <- function(port) {
  tryCatch({
    suppressWarnings(con <- socketConnection("127.0.0.1", port))
    close(con)
    TRUE
  }, error = function(e) FALSE)
}

