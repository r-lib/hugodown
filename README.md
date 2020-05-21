
# hugodown

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

hugodown is an experimental package that aims to faciliate the use of [RMarkdown](http://rmarkdown.rstudio.com/) and [hugo](http://gohugo.io/) together. It's similar to [blogdown](https://bookdown.org/yihui/blogdown/), but is focussed purely on Hugo websites, and enforces a stricter partitioning of roles: hugodown is responsible for transforming `.Rmd` to `.md`, and is hugo responsible for transforming `.md` to `.html`.

## Installation

hugodown isn't available from CRAN yet (and might never be), but you can install the development version from GitHub with:

``` r
devtools::install_github("r-lib/hugodown")
```

## Usage

The key to using hugodown is to put `output: hugodown::hugo_document()` in the YAML metadata of your `.Rmd` files. Then knitting the file will generate a `.md` file designed to work well with hugo. The rest of hugodown just makes your life a little easier:

* `server_start()` will automatically start a hugo server in the background,
  automatically preivewing your site as you update it.

* `post_create()` will creates a new post (filling in default content from
  the hugo [archetype](https://gohugo.io/content-management/archetypes/)).
  
* `site_outdated()` lists all `.Rmd` files that need to be re-rendered 
  (i.e. they have changed since the last time their `.md` was rendered).

## Configuration

hugodown does not work with every possible hugo site. There is some config that we assume:

*   You must use the goldmark markdown renderer, and set `unsafe: true`

    ```yaml
    markup:
      defaultMarkdownHandler: goldmark
      goldmark:
        renderer:
          unsafe: true
      highlight:
        style: pygments
    ```

* We recommend ignoring knitr intermediates:

  ```yaml
  ignoreFiles: ['\.Rmd$', '_files$', '_cache$', '\.knit\.md$', '\.utf8\.md$']
  ```

* To use html widgets, you must **TODO**.

* To use mathjax, you must **TODO**.
