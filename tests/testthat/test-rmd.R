test_that("errors are handled gracefully", {
  rmd <- local_rmd(test_path("error.Rmd"))
  expect_output(
    expect_error(rmd_build(rmd, quiet = TRUE), class = "callr_error")
  )

  # expect_equal(length(dir_ls(path_dir(rmd))), 1L)
})

test_that("figures placed in figs/ directory", {
  rmd <- local_rmd(test_path("plot.Rmd"))
  out <- rmd_build(rmd, quiet = TRUE)

  figs <- path(path_dir(rmd), "figs")
  expect_true(dir_exists(figs))
  expect_equal(length(dir_ls(figs)), 1L)
})

test_that("yaml header is preserved", {
  rmd <- local_rmd(test_path("meta.Rmd"))
  out <- rmd_build(rmd, quiet = TRUE)

  expect_equal(rmd_yaml(rmd), rmd_yaml(out))
})

test_that("html dependencies are captured", {
  rmd <- local_rmd(test_path("widget.Rmd"))
  out <- rmd_build(rmd, quiet = TRUE)

  # Have copied over dependencies
  widget_js <- path(path_dir(out), paste0("htmlwidgets-", packageVersion("htmlwidgets")))
  expect_true(dir_exists(widget_js))

  # And written in yaml metadata
  yaml <- rmd_yaml(out)
  expect_type(yaml$html_dependencies, "character")
  expect_true(length(yaml$html_dependencies) > 1)
})
