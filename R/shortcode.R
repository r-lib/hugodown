shortcode <- function(.name, ..., .contents = NULL, .output = c("html", "md"), .inline = FALSE) {
  call <- paste0(c(.name, shortcode_args(...)), collapse = " ")
  wrap <- switch(arg_match(.output),
    html = function(x) paste0("{{< ", x, " >}}"),
    md = function(x) paste0("{{% ", x, " %}}"),
  )

  if (is.null(.contents)) {
    out <- wrap(call)
  } else {
    out <- paste0(wrap(call), .contents, wrap(paste0("/", name)))
  }

  if (.inline) {
    paste0("`", out, "`{=html}")
  } else {
    paste0("```{=html}\n", out, "\n```\n")
  }
}

shortcode_args <- function(...) {
  args <- list2(...)
  args <- args[!vapply(args, is.null, logical(1))]

  if (length(args) == 0) {
    return(NULL)
  }

  names <- names2(args)

  as_value <- function(x) {
    if (is.character(x)) {
      encodeString(x, quote = "'")
    } else {
      format(x)
    }
  }
  values <- vapply(args, as_value, character(1))
  equals <- ifelse(names == "", "", "=")

  paste0(names, equals, values, collapse = " ")
}


shortcode_gist <- function(username, id, filename = NULL) {
  shortcode("gist", username, id, filename)
}

shortcode_param <- function(name) {
  shortcode("gist", name, .inline = TRUE)
}
