setwd("C:/Git/Hades")
packages <- read.csv("extras/packages.csv", stringsAsFactors = FALSE)
packages <- packages[order(packages$name), ]

headerFile <- "extras/packageStatusHeader.Rmd"
lines <- gsub("\r", "", readChar(headerFile, file.info(headerFile)$size))
lines <- c(lines, "| Package             | Maintainer(s)     | Availability | Build status | Coverage   |")
lines <- c(lines, "| :------------------ | :---------------- | :------: | :-----------: | :--------: |")
for (i in 1:nrow(packages)) {
  name <- packages$name[i]
  if (packages$inCran[i]) {
    availability <- "CRAN"
  } else {
    availability <- "GitHub"
  }
  lines <- c(lines, sprintf("| %s | %s | %s | [![Build Status](https://github.com/OHDSI/%s/workflows/R-CMD-check/badge.svg)](https://github.com/OHDSI/%s/actions?query=workflow%%3AR-CMD-check) | [![codecov.io](https://codecov.io/github/OHDSI/%s/coverage.svg?branch=master)](https://codecov.io/github/OHDSI/%s?branch=master) |", 
							name, 
							packages$maintainers[i], 
							availability, 
							name, 
							name,
							name,
							name))
}
write(lines, "Rmd/packageStatuses.Rmd")
