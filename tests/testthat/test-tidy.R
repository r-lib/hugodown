
test_that("tidy_thumnail() complains about bad inputs", {
  skip_if_not_installed("magick")

  thumb_path <- function(x) test_path("thumbs", x)
  expect_error(tidy_thumbnails(thumb_path("missing")), "Can't find")
  expect_error(tidy_thumbnails(thumb_path("not-square")), "not square")
  expect_error(tidy_thumbnails(thumb_path("too-narrow")), "too narrow")
})

test_that("tidy_thumbnail() modifies images", {
  skip_if_not_installed("magick")
  path <- local_site(test_path("thumbs", "ok"))

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
  verify_output(test_path("test-tidy-pleased.txt"), {
    set.seed(1014)
    writeLines(replicate(20, tidy_pleased()))
  })
})
