test_that("can extract basic config options", {
  config <- hugo_config(test_path("minimal/"))
  expect_type(config, "list")

  expect_equal(hugo_config_bool(config, "builddrafts"), FALSE)
  expect_equal(hugo_config_int(config, "paginate"), 10)
  expect_equal(hugo_config_str(config, "themesdir"), "themes")
})

test_that("can override config with env var", {
  config1 <- hugo_config(test_path("minimal/"))
  expect_equal(hugo_config_bool(config1, "builddrafts"), FALSE)

  config2 <- hugo_config(test_path("minimal/"), c(builddrafts = "true"))
  expect_equal(hugo_config_bool(config2, "builddrafts"), TRUE)
})
