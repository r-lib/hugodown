test_that("can start, restart, and stop server", {
  skip_if_no_hugo()
  site <- test_path("minimal")

  server_start(site, browse = FALSE)
  expect_true(server_running())
  expect_true(port_active(1313))

  server_start(site, browse = FALSE)
  expect_true(server_running())

  server_stop()
  expect_false(server_running())
  expect_false(port_active(1313))
})
