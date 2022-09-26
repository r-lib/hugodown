first_path <- function(paths) {
  for (path in paths) {
    if (file_exists(path)) {
      return(path)
    }
  }

  abort(c(
    "Can't find any of the following candidate paths",
    paths
  ))
}

# copies from withr
set_envvar <- function(envs, action = "replace") {
  if (length(envs) == 0) return()

  stopifnot(is_named(envs))
  stopifnot(is.character(action), length(action) == 1)
  action <- match.arg(action, c("replace", "prefix", "suffix"))

  # if there are duplicated entries keep only the last one
  envs <- envs[!duplicated(names(envs), fromLast = TRUE)]

  old <- Sys.getenv(names(envs), names = TRUE, unset = NA)
  set <- !is.na(envs)

  both_set <- set & !is.na(old)
  if (any(both_set)) {
    if (action == "prefix") {
      envs[both_set] <- paste(envs[both_set], old[both_set])
    } else if (action == "suffix") {
      envs[both_set] <- paste(old[both_set], envs[both_set])
    }
  }

  if (any(set))  do.call("Sys.setenv", as.list(envs[set]))
  if (any(!set)) Sys.unsetenv(names(envs)[!set])

  invisible(old)
}


# helpers for testing -----------------------------------------------------

xpath_xml <- function(x, xpath = ".") {
  x <- xml2::xml_find_all(x, xpath)
  structure(x, class = c("pkgdown_xml", class(x)))
}
xpath_attr <- function(x, xpath, attr) {
  gsub("\r", "", xml2::xml_attr(xml2::xml_find_all(x, xpath), attr), fixed = TRUE)
}
xpath_text <- function(x, xpath = ".", trim = FALSE) {
  xml2::xml_text(xml2::xml_find_all(x, xpath), trim = trim)
}
xpath_length <- function(x, xpath = ".") {
  length(xml2::xml_find_all(x, xpath))
}
