# To verify: run R check on each HADES package 

install.packages("rcmdcheck")

reticulate::use_virtualenv("r-reticulate")

source("PackageCheckFunctions.R")
saveRDS(prepareForPackageCheck(), "Dependencies.rds")
dependencies <- readRDS("Dependencies.rds")
# Skipping Hydra, as renv seems to clash with skeleton renv environments:
dependencies <- dependencies[dependencies$name != "Hydra", ]
for (i in 1:nrow(dependencies)) {
  checkPackage(package = dependencies$name[i], inCran = dependencies$inCran[i])

}
unlink("Dependencies.rds")
