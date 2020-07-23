# Generate site from markdown files --------------------------------------

# You'll need the icon package:
devtools::install_github("ropenscilabs/icon")


setwd("C:/Git/Hades/Rmd")

# Generate packages markdown file
source("extras/GeneratePackagesPage.R")

# Generate support markdown file
source("extras/GenerateSupportPage.R")

# Run this in standalone R session. Runs orders of magnitude faster compared 
# to running in RStudio:
rmarkdown::render_site()
