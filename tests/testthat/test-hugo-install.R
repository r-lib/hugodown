test_that("can retrieve download urls", {
  skip_on_cran()

  expect_equal(
    hugo_release("0.69.0", "Linux")$url,
    "https://github.com/gohugoio/hugo/releases/download/v0.69.0/hugo_extended_0.69.0_Linux-64bit.tar.gz"
  )

  expect_error(hugo_release("foo", "Linux"), "Can't find version")
  expect_error(hugo_release("0.69.0", "Linux", arch = "blah"), "Can't find release")
})

test_that("can install specified linux/mac version", {
  skip_on_cran()
  old <- hugo_default_get()
  on.exit(hugo_default_set(old))

  home <- hugo_home("0.55.0", "Linux")
  if (dir_exists(home)) dir_delete(home)
  suppressMessages(hugo_install("0.55.0", "Linux"))
  expect_true(file_exists(path(home, "hugo")))

  # Returns early if already installed
  suppressMessages(
    expect_message(hugo_install("0.55.0", "Linux"), "installed")
  )
})

test_that("can install specified windows version", {
  skip_on_cran()
  old <- hugo_default_get()
  on.exit(hugo_default_set(old))

  home <- hugo_home("0.55.0", "Windows")
  if (dir_exists(home)) dir_delete(home)
  suppressMessages(hugo_install("0.55.0", "Windows"))
  expect_true(file_exists(path(home, "hugo.exe")))
})

test_that("can get, set, and increment version", {
  old <- hugo_default_get()
  on.exit(hugo_default_set(old))

  if (file_exists(hugo_default_path())) {
    file_delete(hugo_default_path())
  }

  expect_equal(hugo_default_get(), NA)
  hugo_default_inc("0.1.0")
  expect_equal(hugo_default_get(), package_version("0.1.0"))
  hugo_default_inc("0.0.1")
  expect_equal(hugo_default_get(), package_version("0.1.0"))
  hugo_default_inc("1.0.0")
  expect_equal(hugo_default_get(), package_version("1.0.0"))
})
