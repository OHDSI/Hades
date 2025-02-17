# setwd("C:/Temp/Git/Hades")
packages <- read.csv("extras/packages.csv", stringsAsFactors = FALSE)
packages <- packages[order(packages$name), ]

headerFile <- "extras/packageStatusHeader.Rmd"
lines <- gsub("\r", "", readChar(headerFile, file.info(headerFile)$size))
lines <- c(lines, "| Package            | Version | Maintainer(s)   | Availability | Open issues | Open pull-requests | Build status | Coverage   | PaRe   |")
lines <- c(lines, "| :----------------- | :----: |:--------------- | :------: | :------: | :------: | :------------: | :----------: | :------ |")
rowTemplate <- "| [%pkg%](https://github.com/%org%/%pkg%) | [![Version](https://img.shields.io/github/r-package/v/%org%/%pkg%?label=%20)](https://%org%.github.io/%pkg%/) | %maintainer% | %availability% | [![Open issues](https://img.shields.io/github/issues-raw/%org%/%pkg%?label=%20)](https://github.com/%org%/%pkg%/issues) | [![Open pull-requests](https://img.shields.io/github/issues-pr-raw/%org%/%pkg%?label=%20)](https://github.com/%org%/%pkg%/pulls) | %status% | [![codecov.io](https://codecov.io/github/%org%/%pkg%/coverage.svg?branch=main)](https://codecov.io/github/%org%/%pkg%?branch=main) | [Report](https://%org%.github.io/HadesFiles/pare_reports/%pkg%.html)"
githubStatusTemplate <- "[![Build Status](https://github.com/%org%/%pkg%/actions/workflows/R_CMD_check_main_weekly.yaml/badge.svg)](https://github.com/%org%/%pkg%/actions/workflows/R_CMD_check_main_weekly.yaml)"
cranStatusTemplate <- "[![Build Status](https://badges.cranchecks.info/worst/%pkg%.svg)](https://cran.r-project.org/web/checks/check_results_%pkg%.html)"

for (i in 1:nrow(packages)) {
  name <- packages$name[i]
  if (packages$inCran[i]) {
    availability <- "CRAN"
  } else {
    availability <- "GitHub"
  }
  lines <- c(lines, gsub("%org%", packages$organization[i], 
                         gsub("%pkg%", packages$name[i], 
                              gsub("%maintainer%", packages$maintainers[i],
                                   gsub("%availability%", availability,
                                        gsub("%status%", if (packages$inCran[i]) cranStatusTemplate else githubStatusTemplate,
                                        rowTemplate))))))
}
write(lines, "Rmd/packageStatuses.Rmd")
