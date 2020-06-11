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
