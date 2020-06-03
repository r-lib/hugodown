
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
