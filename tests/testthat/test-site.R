test_that("recognises major config formats", {
  toml <- as.character(path_abs(test_path("config-toml")))
  expect_equal(site_root(toml), toml)

  yaml <- as.character(path_abs(test_path("config-yaml")))
  expect_equal(site_root(yaml), yaml)

  yml <- as.character(path_abs(test_path("config-yml")))
  expect_equal(site_root(yml), yml)
})

test_that("walks up path to find root", {
  outdated <- as.character(path_abs(test_path("outdated")))
  expect_equal(site_root(path(outdated, "content")), outdated)
  expect_equal(site_root(path(outdated, "content", "blog")), outdated)

  expect_error(site_root(test_path(".")), "config")
})

test_that("can find hugodown config", {
  config <- site_config(test_path("config-hugodown"))
  expect_equal(config, list(test = TRUE, hugo_version = "0.66.0"))
})

# out of date -------------------------------------------------------------

test_that("old blogdown posts don't need render", {
  blog <- test_path("outdated/content/blog")

  expect_false(rmd_needs_render(path(blog, "ok-no-hash/index.Rmd")))
  expect_false(rmd_needs_render(path(blog, "ok-has-html/index.Rmd")))
})

test_path("site_outdated() processes whole directory", {
  site <- test_path("outdated")
  outdated <- as.character(path_rel(site_outdated(site), site))

  expect_equal(outdated, c(
    "content/blog/outdated-no-md/index.Rmd",
    "content/blog/outdated-old-hash/index.Rmd"
  ))
})
