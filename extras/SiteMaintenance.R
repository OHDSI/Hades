# Generate site from markdown files --------------------------------------

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

rmarkdown::render_site("Rmd")
