# Generate site from markdown files --------------------------------------

setwd("c:/temp/git/Hades")
setwd("C:/Users/admin_mschuemi/Documents/git/Hades")

# You'll need the icon package:
remotes::install_github("ropenscilabs/icon")

# May need to install pandoc:
install.packages("installr")
installr::install.pandoc()


# Generate packages markdown file
source("extras/GeneratePackagesPage.R")

# Generate support markdown file
source("extras/GenerateSupportPage.R")

# Generate package status markdown file
source("extras/GeneratePackageStatusPage.R")

# Generate testing server usage table contents
source("extras/DatabaseTestServerUsage.R")

# Generate supported platforms markdown file
source("extras/GenerateSupportedPlatformsPage.R")


# Run this in standalone R session. Runs orders of magnitude faster compared 
# to running in RStudio:
rmarkdown::find_pandoc(dir = "C:/Users/mschuemi/AppData/Local/Pandoc")
rmarkdown::render_site("Rmd")
dir.create("docs/pare_reports")
file.copy("extras/pare_reports", "docs", recursive = TRUE)
