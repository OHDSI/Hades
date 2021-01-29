# Generate site from markdown files --------------------------------------

setwd("c:/git/Hades")

# You'll need the icon package:
devtools::install_github("ropenscilabs/icon")

# Generate packages markdown file
source("extras/GeneratePackagesPage.R")

# Generate support markdown file
source("extras/GenerateSupportPage.R")

# Generate package status markdown file
source("extras/GeneratePackageStatusPage.R")


# Run this in standalone R session. Runs orders of magnitude faster compared 
# to running in RStudio:
rmarkdown::render_site("Rmd")
