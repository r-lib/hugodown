test_that("errors are handled gracefully", {
  rmd <- local_file(test_path("error.Rmd"))
  expect_message(expect_error(rmarkdown::render(rmd, quiet = TRUE), "Failure"))
  expect_equal(length(dir_ls(path_dir(rmd))), 1L)
})

test_that("figures placed in figs/ directory", {
  rmd <- local_file(test_path("plot.Rmd"))
  rmarkdown::render(rmd, quiet = TRUE)

  figs <- path(path_dir(rmd), "figs")
  expect_true(dir_exists(figs))
  expect_equal(length(dir_ls(figs)), 1L)
})

test_that("tables use pipes", {
  rmd <- local_file(test_path("table.Rmd"))
  rmarkdown::render(rmd, quiet = TRUE)
  out <- path(path_dir(rmd), "table.md")

  lines <- brio::read_lines(out)
  expect_equal(sum(grepl("|", lines, fixed = TRUE)), 4)
})

test_that("code is linked/highlighted", {
  rmd <- local_file(test_path("code.Rmd"))
  rmarkdown::render(rmd, quiet = TRUE)
  out <- path(path_dir(rmd), "code.md")

  lines <- brio::read_lines(out)
  expect_equal(sum(grepl("<pre", lines, fixed = TRUE)), 2)
  expect_equal(sum(grepl("[`stats::median()`]", lines, fixed = TRUE)), 1)
})

test_that("markdown div syntax is converted to native divs", {
  rmd <- local_file(test_path("div.Rmd"))
  rmarkdown::render(rmd, quiet = TRUE)
  out <- path(path_dir(rmd), "div.md")

  lines <- brio::read_lines(out)
  expect_equal(sum(grepl("div", lines, fixed = TRUE)), 2)
})

test_that("math is untransformed", {
  rmd <- local_file(test_path("math.Rmd"))
  rmarkdown::render(rmd, quiet = TRUE)
  out <- path(path_dir(rmd), "math.md")

  lines <- brio::read_lines(out)
  expect_equal(lines[length(lines) - 1], "$a_1 + b_2$")
})

test_that("hash added to yaml header", {
  rmd <- local_file(test_path("meta.Rmd"))
  rmarkdown::render(rmd, quiet = TRUE)
  out <- path(path_dir(rmd), "meta.md")

  yaml <- rmarkdown::yaml_front_matter(rmd)
  yaml$rmd_hash <- rmd_hash(rmd)
  expect_equal(rmarkdown::yaml_front_matter(out), yaml)

  # Test that yaml is preserved as is (i.e. no round-tripping)
  lines <- brio::read_lines(out)
  expect_equal(lines[[4]], "# this is a comment")
})

test_that("html dependencies are captured", {
  rmd <- local_file(test_path("widget.Rmd"))
  rmarkdown::render(rmd, quiet = TRUE)
  out <- path(path_dir(rmd), "widget.md")

  # Have copied over dependencies
  widget_js <- path(path_dir(rmd), paste0("htmlwidgets-", packageVersion("htmlwidgets")))
  expect_true(dir_exists(widget_js))

  # And written in yaml metadata
  yaml <- rmarkdown::yaml_front_matter(out)
  expect_type(yaml$html_dependencies, "character")
  expect_true(length(yaml$html_dependencies) > 1)
})


# helpers -----------------------------------------------------------------

test_that("link_inline() works with an nubmer of links", {
  expect_equal(link_inline("a"), "a")
  expect_equal(link_inline("`b`"), "`b`")
  expect_equal(link_inline("`c` `d`"), "`c` `d`")

  expect_equal(
    link_inline("`stats::median`"),
    "[`stats::median`](https://rdrr.io/r/stats/median.html)"
  )
})

test_that("link_inline() doesn't link within links or headers", {
  expect_equal(link_inline("# `base::t`"), "# `base::t`")
  expect_equal(link_inline("[`base::t`]()"), "[`base::t`]()")
  expect_equal(link_inline("<pre>\n`base::t`</pre>"), "<pre>\n`base::t`</pre>")
})
