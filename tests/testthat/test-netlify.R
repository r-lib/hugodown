test_that("multiplication works", {
  path <- local_dir(test_path("config-hugodown"))
  use_netlify_toml(path)

  expect_true(file_exists(path(path, "netlify.toml")))

  toml <- RcppTOML::parseTOML(path(path, "netlify.toml"))
  expect_equal(toml$build$environment$HUGO_VERSION, "0.66.0")
})
