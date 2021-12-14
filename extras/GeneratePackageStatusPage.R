setwd("C:/Temp/Git/Hades")
packages <- read.csv("extras/packages.csv", stringsAsFactors = FALSE)
packages <- packages[order(packages$name), ]

headerFile <- "extras/packageStatusHeader.Rmd"
lines <- gsub("\r", "", readChar(headerFile, file.info(headerFile)$size))
lines <- c(lines, "| Package            | Version | Maintainer(s)   | Availability | Open issues | Open pull-requests | Build status | Coverage   |")
lines <- c(lines, "| :----------------- | :----: |:--------------- | :------: | :------: | :------: | :------------: | :----------: |")
for (i in 1:nrow(packages)) {
  name <- packages$name[i]
  if (packages$inCran[i]) {
    availability <- "CRAN"
  } else {
    availability <- "GitHub"
  }
  lines <- c(lines, sprintf("| [%s](https://github.com/OHDSI/%s) | [![Version](https://img.shields.io/github/r-package/v/ohdsi/%s?label=%%20)](https://ohdsi.github.io/%s/) | %s | %s | [![Open issues](https://img.shields.io/github/issues-raw/OHDSI/%s?label=%%20)](https://github.com/OHDSI/%s/issues) | [![Open pull-requests](https://img.shields.io/github/issues-pr-raw/OHDSI/%s?label=%%20)](https://github.com/OHDSI/%s/pulls) | [![Build Status](https://github.com/OHDSI/%s/workflows/R-CMD-check/badge.svg)](https://github.com/OHDSI/%s/actions?query=workflow%%3AR-CMD-check) | [![codecov.io](https://codecov.io/github/OHDSI/%s/coverage.svg?branch=master)](https://codecov.io/github/OHDSI/%s?branch=master) |", 
							name,
							name,
							name,
							name,
							packages$maintainers[i], 
							availability, 
							name, 
							name, 
							name, 
							name, 
							name, 
							name,
							name,
							name))
}
write(lines, "Rmd/packageStatuses.Rmd")
