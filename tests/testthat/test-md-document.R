test_that("errors are handled gracefully", {
  rmd <- local_file(test_path("error.Rmd"))
  expect_message(expect_error(rmarkdown::render(rmd, quiet = TRUE), "Failure"))
  expect_equal(length(dir_ls(path_dir(rmd))), 1L)
})

test_that("figures placed in figs/ directory", {
  rmd <- local_render(test_path("plot.Rmd"))

  figs <- path(rmd$dir, "figs")
  expect_true(dir_exists(figs))
  expect_equal(length(dir_ls(figs)), 2L)

  # Check we're not converting percentage widths to latex
  expect_match(rmd$lines[[15]], 'width="50%"')
})

test_that("tables use pipes", {
  rmd <- local_render(test_path("table.Rmd"))
  expect_equal(sum(grepl("|", rmd$lines, fixed = TRUE)), 4)
})

test_that("code is linked/highlighted", {
  rmd <- local_render(test_path("code.Rmd"))

  expect_equal(sum(grepl("<pre", rmd$lines, fixed = TRUE)), 2)
  expect_equal(sum(grepl("[`stats::median()`]", rmd$lines, fixed = TRUE)), 1)
})

test_that("output gets unicode and colour", {
  skip_on_os("windows")

  rmd <- local_render(test_path("output.Rmd"))
  expect_match(rmd$lines[[9]], "color: #0000BB")
  expect_match(rmd$lines[[10]], "#&gt; \u2714")
})

test_that("interweaving of code and output generates correct html", {
  rmd <- local_render(test_path("knit-hooks.Rmd"))
  verify_output(test_path("test-md-document-hooks.txt"), cat_line(rmd$lines))
})

test_that("markdown div syntax is converted to native divs", {
  rmd <- local_render(test_path("div.Rmd"))
  expect_equal(sum(grepl("div", rmd$lines, fixed = TRUE)), 2)
})

test_that("emojis are preserved", {
  rmd <- local_render(test_path("emoji.Rmd"))
  expect_equal(rmd$lines[[7]], ":smile_cat:")
})

test_that("math is untransformed", {
  rmd <- local_render(test_path("math.Rmd"))
  expect_equal(rmd$lines[[7]], "$a_1 + b_2$")
})

test_that("raw html is preserved", {
  rmd <- local_render(test_path("raw-html.Rmd"))
  expect_equal(rmd$lines[[7]], "<raw>")
  expect_equal(rmd$lines[[9]], "This is <raw>")
})

test_that("hash added to yaml header", {
  rmd <- local_render(test_path("meta.Rmd"))

  yaml <- rmarkdown::yaml_front_matter(rmd$src)
  yaml$rmd_hash <- rmd_hash(rmd$src)
  expect_equal(rmarkdown::yaml_front_matter(rmd$dst), yaml)

  # Test that yaml is preserved as is (i.e. no round-tripping)
  expect_equal(rmd$lines[[4]], "# this is a comment")
})

test_that("html dependencies are captured", {
  rmd <- local_render(test_path("widget.Rmd"))

  # Have copied over dependencies
  widget_js <- path(rmd$dir, paste0("htmlwidgets-", packageVersion("htmlwidgets")))
  expect_true(dir_exists(widget_js))

  # And written in yaml metadata
  yaml <- rmarkdown::yaml_front_matter(rmd$dst)
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
