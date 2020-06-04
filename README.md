
# hugodown <img src='man/figures/logo.png' align="right" height="138.5" />

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![R build status](https://github.com/r-lib/hugodown/workflows/R-CMD-check/badge.svg)](https://github.com/r-lib/hugodown/actions)
[![Codecov test coverage](https://codecov.io/gh/r-lib/hugodown/branch/master/graph/badge.svg)](https://codecov.io/gh/r-lib/hugodown?branch=master)
<!-- badges: end -->

hugodown is an experimental package that aims to facilitate the use of [RMarkdown](http://rmarkdown.rstudio.com/) and [hugo](http://gohugo.io/) together. It's similar to [blogdown](https://bookdown.org/yihui/blogdown/), but is focussed purely on Hugo websites, and enforces a stricter partitioning of roles: hugodown is responsible for transforming `.Rmd` to `.md`, and is hugo responsible for transforming `.md` to `.html`.

## Compared to blogdown

Probably the biggest advantage of hugodown over blogdown is that it only re-runs your R code when you explicitly ask for it (by knitting the post). This makes hugodown considerably easy to use for long-running blogs and blogs with multiple contributors. Otherwise, it provides the best of blogdown's [two Rmarkdown variants](https://bookdown.org/yihui/blogdown/output-format.html): `.Rmd` and `.Rmarkdown`. 

| Feature               | hugodown `.Rmd` | blogdown `.Rmd` | blogdown `.Rmarkdown` |
|-----------------------|-----------------|-----------------|-----------------------|
| Output                | `.md`           | `.html`         | `.markdown`           |
| Runs R code           | y               | y               | y                     |
| Table of contents     | y               | n               | y                     |
| Bibliography          | y               | y               | n                     |
| MathJax               | y               | y               | ?                     |
| HTML widgets          | y               | y               | n                     |
| Cross-references      | n               | y               | y                     |

The only current limitation is that it does not support within page cross-references to figures, tables, and equations.

## Installation

hugodown isn't available from CRAN yet (and might never be), but you can install the development version from GitHub with:

``` r
devtools::install_github("r-lib/hugodown")
```

## Usage

The key to using hugodown is to put `output: hugodown::hugo_document()` in the YAML metadata of your `.Rmd` files. Then knitting the file will generate a `.md` file designed to work well with hugo. The rest of hugodown just makes your life a little easier:

* `server_start()` will automatically start a hugo server in the background,
  automatically previewing your site as you update it.

* `post_create()` will creates a new post (filling in default content from
  the hugo [archetype](https://gohugo.io/content-management/archetypes/)).
  
* To knit an `.Rmd` post, you can use the Knit button to knit to the correct output format. You can also use the keyboard shortcut `Cmd+Shift+K` (Mac) or `Ctrl+Shift+K` (Windows/Linux).
  
* `site_outdated()` lists all `.Rmd` files that need to be re-rendered 
  (i.e. they have changed since the last time their `.md` was rendered).
  
With hugodown, knitting an individual post and building the site are two separate processes. A good workflow when working with an existing Hugo site in RStudio is to open the site's `.Rproj` file, use `server_start()`, then add or edit your posts. Because the hugo server will only add `.Rmd` content to your site preview after knitting, you'll need to use the keyboard shortcut to knit first. If you have already used `server_start()`, the knitted output will be previewable; if not, you can start the server after knitting to preview the full site.

### Citations

To use citations in a blog post, just provide a `bibliography` in the YAML metadata. If you want to use footnotes for citations (a style that generally works well in blogs), you'll need to find a footnote style CSL file (e.g. [`chicago-fullnote-bibliography.csl`][footnote-csl], and use the following YAML header.

```yaml
bibliography: refs.bib
suppress-bibliography: true
csl: chicago-fullnote-bibliography.csl
```

## Configuration

hugodown does not work with every possible hugo site. There is some config that we assume (typically in `config.toml`, but hugo has a bewildering array of places that this might live instead.)

*   You must use the goldmark markdown renderer, and set `unsafe: true`

    ```toml
    [markup]
      defaultMarkdownHandler = "goldmark"
      [markup.goldmark.renderer]
        unsafe = true
    ```

*   For best syntax hightling results, you'll must classes:

    ```toml
    pygmentsUseClasses = true
    ```
    
    And then ensure that your stylesheet defines styles for the appropriate 
    classes. You can generate starter css with (e.g):
    
    ```
    hugo gen chromastyles --style=monokai
    ```
    
    Substitute `monokai` for the [style of your choice][styles].

*   We recommend ignoring knitr intermediates:

    ```toml
    ignoreFiles = ['\.Rmd$', '_files$', '_cache$', '\.knit\.md$', '\.utf8\.md$']
    ```

*   To use html widgets, you must include the following Go template somewhere
    in the `<head>` layout file for your theme. This will help Hugo find the 
    HTML dependencies needed to render the widget in a post. You may find this 
    [blog post](https://zwbetz.com/override-a-hugo-theme/) helpful for 
    overriding Hugo layouts.
  
    ```
    {{ range .Params.html_dependencies }}
      {{ . | safeHTML }}
    {{ end }}
    ```

*   To use mathjax, you will need to use a series of [small hacks][yihui-mathjax]. 
    The easiest way is to copy from an existing template, like [tourmaline].
    Take note of the [`footer_mathjax.html`][footer_mathjax] partial, which
    is then included in the [`footer.html`][footer]. You'll also need to include
    [`math_code.js`][math_code] in your `static/` directory. Once that's done
    you can use inline math like `$math$`, and display math like 
    `` `$$ math $$` `` (note the extra backtick compared to usual).

## Converting from blogdown

* Make sure your post archetype has extension `.Rmd` and includes
  `output: hugodown::hugo_document` in the YAML. The post archetype
  should typically be `archetypes/blog/index.Rmd`.
  
* Delete `index.Rmd` from the root of your site.

[yihui-mathjax]: https://yihui.org/en/2018/07/latex-math-markdown/ 
[tourmaline]: https://github.com/rstudio/hugo-tourmaline
[footer_mathjax]: https://github.com/rstudio/hugo-tourmaline/blob/master/layouts/partials/footer_mathjax.html
[footer]: https://github.com/rstudio/hugo-tourmaline/blob/master/layouts/partials/footer.html#L22
[math_code]: https://github.com/rstudio/hugo-tourmaline/blob/master/static/js/math-code.js
[styles]: https://xyproto.github.io/splash/docs/all.html
[footnote-csl]: https://github.com/citation-style-language/styles/blob/master/chicago-fullnote-bibliography.csl)
