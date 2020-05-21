test_that("errors are handled gracefully", {
  rmd <- local_rmd(test_path("error.Rmd"))
  expect_message(expect_error(rmarkdown::render(rmd, quiet = TRUE), "Failure"))
  expect_equal(length(dir_ls(path_dir(rmd))), 1L)
})

test_that("figures placed in figs/ directory", {
  rmd <- local_rmd(test_path("plot.Rmd"))
  rmarkdown::render(rmd, quiet = TRUE)

  figs <- path(path_dir(rmd), "figs")
  expect_true(dir_exists(figs))
  expect_equal(length(dir_ls(figs)), 1L)
})

test_that("hash added to yaml header", {
  rmd <- local_rmd(test_path("meta.Rmd"))
  rmarkdown::render(rmd, quiet = TRUE)
  out <- path(path_dir(rmd), "meta.md")

  yaml <- rmarkdown::yaml_front_matter(rmd)
  yaml$rmd_hash <- "830128b82cad99ab"

  expect_equal(rmarkdown::yaml_front_matter(out), yaml)
})

test_that("html dependencies are captured", {
  rmd <- local_rmd(test_path("widget.Rmd"))
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
