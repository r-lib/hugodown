test_that("can find version from hugodown.yml", {
  expect_equal(hugo_version(test_path("config-hugodown")), "0.66.0")
})

test_that("falls back to latest with a warning", {
  expect_warning(out <- hugo_version(test_path("config-toml")), "install")
  expect_equal(out, hugo_default_get())
})
