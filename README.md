# Hades
[Under development] A central repository for things related to HADES

This builds the [HADES website](https://ohdsi.github.io/Hades).

# Requirements

Make sure you have the icon package installed:
```r
devtools::install_github("ropenscilabs/icon")
```

```r
shell("R -e 'rmarkdown::build_site()'")

shell("R -e rmarkdown::render_site()")
```