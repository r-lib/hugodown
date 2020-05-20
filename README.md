
# hugodown

<!-- badges: start -->
<!-- badges: end -->

The goal of hugodown is to make it easy to use RMarkdown within a [hugo](http://gohugo.io/) website. It's similar to [blogdown](https://bookdown.org/yihui/blogdown/), but is focussed purely on hugo websites, and enforces a stricter partitioning of roles: hugodown is responsible for transforming `.Rmd` to `.md`, and is hugo responsible for transforming `.md` to `.html`.

## Installation

hugodown isn't available from CRAN yet, but you can install the development version from GitHub with:

``` r
devtools::install_github("r-lib/hugodown")
```

## Configuation

In order to make the implementation of hugodown simpler, it enforces a few restrictions on your hugo site:

* You must use a yaml config file.

* You must use the goldmark markdown renderer with `unsafe: true`.

* If you want to support html widgets, you must TBA.
