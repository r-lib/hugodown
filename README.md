
# hugodown <img src='man/figures/logo.png' align="right" height="138.5" />

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![R-CMD-check](https://github.com/r-lib/hugodown/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/r-lib/hugodown/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/r-lib/hugodown/branch/master/graph/badge.svg)](https://codecov.io/gh/r-lib/hugodown?branch=master)
<!-- badges: end -->

hugodown is an experimental package that aims to facilitate the use of [RMarkdown](http://rmarkdown.rstudio.com/) and [hugo](http://gohugo.io/) together. It's similar to [blogdown](https://bookdown.org/yihui/blogdown/), but is focussed purely on Hugo websites, and enforces a stricter partitioning of roles: hugodown is responsible for transforming `.Rmd` to `.md`, and hugo is responsible for transforming `.md` to `.html`.

## Compared to blogdown

* It only re-runs your R code when you explicitly ask for it (by knitting the 
  post). This makes hugodown considerably easier to use for long-running blogs 
  and blogs with multiple contributors. 
  
* Local previews are pinned to a specific version of hugo. This makes it easier
  to work with multiple blogs, and protects your from hugo <-> theme 
  version incompatibilities.
  
* It provides support for getting started with a limited number of themes,
  automatically making needed tweaks to ensure that html widgets, syntax 
  highlighting, and math display work out of the box.

* It does not currently support within page cross-references for figures, 
  tables, and equations.

* It is more opinionated about hugo configuration; see `vignette("config")` 
  for details.
  
* It is designed around a single Rmarkdown format, `.Rmd`.

## Installation

hugodown isn't available from CRAN yet (and might never be), but you can install the development version from GitHub with:

``` r
devtools::install_github("r-lib/hugodown")
```

## Usage

The key to using hugodown is to put `output: hugodown::md_document()` in the YAML metadata of your `.Rmd` files. Then knitting the file will generate a `.md` file designed to work well with hugo. The rest of hugodown just makes your life a little easier:

* `hugo_start()` will automatically start a hugo server in the background,
  automatically previewing your site as you update it.

* `use_post()` will create a new post (filling in default content from
  the hugo [archetype](https://gohugo.io/content-management/archetypes/)).
  
* To knit an `.Rmd` post, you can use the Knit button to knit to the correct output format. You can also use the keyboard shortcut `Cmd+Shift+K` (Mac) or `Ctrl+Shift+K` (Windows/Linux).
  
* `site_outdated()` lists all `.Rmd` files that need to be re-rendered 
  (i.e. they have changed since the last time their `.md` was rendered).
  
With hugodown, knitting an individual post and building the site are two separate processes. A good workflow when working with an existing Hugo site in RStudio is to open the site's `.Rproj` file, use `hugo_start()`, then add or edit your posts. Because the hugo server will only add `.Rmd` content to your site preview after knitting, you'll need to use the keyboard shortcut to knit first.

### Citations

To use citations in a blog post, just provide a `bibliography` in the YAML metadata. If you want to use footnotes for citations (a style that generally works well in blogs), you'll need to find a footnote style CSL file (e.g. [`chicago-fullnote-bibliography.csl`][footnote-csl], and use the following YAML header.

```yaml
bibliography: refs.bib
suppress-bibliography: true
csl: chicago-fullnote-bibliography.csl
```

## Converting from blogdown

* Make sure your post archetype has extension `.Rmd` and includes
  `output: hugodown::md_document` in the YAML. The post archetype
  should typically be `archetypes/blog/index.Rmd`.
  
* Delete `index.Rmd` from the root of your site.

* Ensure that hugo is configured as described in `vignette("config")`.

[yihui-mathjax]: https://yihui.org/en/2018/07/latex-math-markdown/ 
[tourmaline]: https://github.com/rstudio/hugo-tourmaline
[footer_mathjax]: https://github.com/rstudio/hugo-tourmaline/blob/master/layouts/partials/footer_mathjax.html
[footer]: https://github.com/rstudio/hugo-tourmaline/blob/master/layouts/partials/footer.html#L22
[math_code]: https://github.com/rstudio/hugo-tourmaline/blob/master/static/js/math-code.js
[styles]: https://xyproto.github.io/splash/docs/all.html
[footnote-csl]: https://github.com/citation-style-language/styles/blob/master/chicago-fullnote-bibliography.csl
