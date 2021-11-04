#' Generate a hugo shortcode
#'
#' @description
#' Generate a hugo shortcode with appropriate pandoc markup to preserve it as
#' is when embedded in an R markdown document.
#'
#' Generally, I don't recommend calling this function directly; instead
#' use it inside a function with the same name as the shortcode you want to
#' wrap. See [embed_gist()] and friends for examples
#'
#' @param .name Name of the shortcode
#' @param ... Arguments to the shortcode, supplied either by name or
#'   position depending on the shortcode. By default, strings will
#'   automatically be quoted with single quotes. Suppress this quoting
#'   by wrapping the argument in `I()`.
#' @param .contents Contents of the shortcode for paired shortcodes.
#' @param .output Is the output of the shortcode html or markdown? This
#'   controls whether the shortcode uses `<>` or `%`.
#' @param .inline Is the shortcode designed to be used inline or in its own
#'   paragraph? Controls whether the shortcode is wrapped in a block or inline
#'   [raw attribute](https://pandoc.org/MANUAL.html#extension-raw_attribute).
#' @export
#' @examples
#' pkg <- function(name) {
#'   shortcode("pkg", name, .inline = TRUE)
#' }
#' pkg("hugodown")
shortcode <- function(.name, ..., .contents = NULL, .output = c("html", "md"), .inline = FALSE) {
  call <- paste0(c(.name, shortcode_args(...)), collapse = " ")
  wrap <- switch(arg_match(.output),
    html = function(x) paste0("{{< ", x, " >}}"),
    md = function(x) paste0("{{% ", x, " %}}"),
  )

  if (is.null(.contents)) {
    out <- wrap(call)
  } else {
    out <- paste0(wrap(call), .contents, wrap(paste0("/", .name)))
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
    if (is.character(x) && !inherits(x, "AsIs")) {
      encodeString(x, quote = "'")
    } else {
      format(x)
    }
  }
  values <- vapply(args, as_value, character(1))
  equals <- ifelse(names == "", "", "=")

  paste0(names, equals, values, collapse = " ")
}


#' Generate hugo shortcodes to embed various types of media
#'
#' @description
#' These are wrappers that make it easy to generate
#' [hugo shortcodes](https://gohugo.io/content-management/shortcodes/) that
#' make it easy to embed various types of media into your pages. You use from
#' inline R code like:
#'
#' ```
#' This tweet announced the release of hugo 0.24:
#'
#' `R embed_tweet("877500564405444608")`
#' ```
#'
#' @param username GitHub/Twitter user name
#' @param id A string giving the object id. You'll usually find this by
#'  inspecting the URL:
#'  * gist: `https://gist.github.com/spf13/7896402` -> `7896402`
#'  * instagram: `https://www.instagram.com/p/BWNjjyYFxVx/` -> `BWNjjyYFxVx`
#'  * twitter: `https://twitter.com/spf13/status/877500564405444608` -> `877500564405444608`
#'  * vimeo: `https://vimeo.com/channels/staffpicks/146022717` -> `146022717`
#'  * youtube: `https://www.youtube.com/watch?v=w7Ft2ymGmfc` -> `w7Ft2ymGmfc`
#' @param filename Pick single file from multiple file gist
#' @export
embed_gist <- function(username, id, filename = NULL) {
  shortcode("gist", username, id, filename)
}
#' @param caption Show instagram caption?
#' @export
#' @rdname embed_gist
embed_instagram <- function(id, caption = TRUE) {
  stopifnot(is.character(id))
  shortcode("instagram", I(id), if (!caption) I("hidecaption"))
}
#' @export
#' @rdname embed_gist
embed_tweet <- function(id, username = NULL) {
  stopifnot(is.character(id))
  shortcode("tweet", username = username, id = id)
}
#' @export
#' @rdname embed_gist
embed_vimeo <- function(id) {
  stopifnot(is.character(id))
  shortcode("vimeo", I(id))
}
#' @param autoplay Automatically play youtube video?
#' @export
#' @rdname embed_gist
embed_youtube <- function(id, autoplay = FALSE) {
  stopifnot(is.character(id))

  if (autoplay) {
    shortcode("youtube", id = I(id), autoplay = "true")
  } else {
    shortcode("youtube", id = id)
  }
}
