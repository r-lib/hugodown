test_that("tidy_post() adds additional data", {
  skip_if_no_hugo()

  site <- local_dir(test_path("archetypes"))
  dir_create(path(site, "content", "blog"))
  test_Rmd <- tidy_post_create("testthat-1-0-0", site = site, open = FALSE)

  rmd <- brio::read_lines(path(test_Rmd, "index.Rmd"))
  expect_equal(rmd[[3]], "package: testthat")
})

test_that("tidy_thumnail() complains about bad inputs", {
  skip_if_not_installed("magick")

  thumb_path <- function(x) test_path("thumbs", x)
  expect_error(tidy_thumbnails(thumb_path("missing")), "Can't find")
  expect_error(tidy_thumbnails(thumb_path("not-square")), "not square")
  expect_error(tidy_thumbnails(thumb_path("too-narrow")), "too narrow")
})

test_that("tidy_thumbnail() modifies images", {
  skip_if_not_installed("magick")
  path <- local_dir(test_path("thumbs", "ok"))

  tidy_thumbnails(path)

  sq <- magick::image_info(magick::image_read(file.path(path, "thumbnail-sq.jpg")))
  expect_equal(sq$width, 300)
  expect_equal(sq$height, 300)

  wd <- magick::image_info(magick::image_read(file.path(path, "thumbnail-wd.jpg")))
  expect_equal(wd$width, 1000)
  expect_equal(wd$height, 200)
})

test_that("check_slug ensures name ok", {
  expect_error(check_slug(1), "single string")
  expect_error(check_slug(letters[1:3]), "single string")

  expect_error(check_slug("bad name"), "must not contain")
  expect_error(check_slug("bad.name"), "must not contain")
  expect_error(check_slug("bad_name"), "must not contain")
})

test_that("tidy_pleased() generates random phrases", {
  skip_if(getRversion() < "3.6") # RNG changed

  verify_output(test_path("test-tidy-pleased.txt"), {
    set.seed(1014)
    writeLines(replicate(20, tidy_pleased()))
  })
})
