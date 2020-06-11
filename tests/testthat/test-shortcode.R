test_that("handles all variants of argument specification", {
  verify_output(test_path("test-shortcode-arguments.txt"), {
    inline <- function(...) cat(shortcode(..., .inline = TRUE))
    "No arguments"
    inline("name")

    "Position vs name"
    inline("name", 1, 2, 3)
    inline("name", x = 1, y = 2, z = 3)

    "Quoting"
    inline("name", "x")
    inline("name", I("'x'"))

    "Contents"
    inline("name", .contents = "contents")
  })
})

test_that("handles md and html output", {
  verify_output(test_path("test-shortcode-wrapper.txt"), {
    "type"
    cat(shortcode("name", .output = "md"))
    cat(shortcode("name", .output = "html"))
  })
})


test_that("test built-in embed shortcodes", {
  verify_output(test_path("test-shortcode-embed.txt"), {
    embed_gist("spf13", "7896402")

    embed_instagram("BWNjjyYFxVx", caption = TRUE)
    embed_instagram("BWNjjyYFxVx", caption = FALSE)

    embed_tweet("877500564405444608")

    embed_vimeo("146022717")

    embed_youtube("w7Ft2ymGmfc", autoplay = FALSE)
    embed_youtube("w7Ft2ymGmfc", autoplay = TRUE)
  })
})
