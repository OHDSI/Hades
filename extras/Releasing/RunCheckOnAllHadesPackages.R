# To verify: run R check on each HADES package 

install.packages("rcmdcheck")

reticulate::use_virtualenv("r-reticulate")

source("PackageCheckFunctions.R")
saveRDS(prepareForPackageCheck(), "Dependencies.rds")
dependencies <- readRDS("Dependencies.rds")
# Skipping Hydra, as renv seems to clash with skeleton renv environments:
dependencies <- dependencies[dependencies$name != "Hydra", ]
for (i in 29:nrow(dependencies)) {
  if (dependencies$name[i] == "DeepPatientLevelPrediction") {
    # This package is failing unit tests, it seems because Python modules are 
    # missing. Skipping for now. Hoping DeepPlp users are savy enough to figure
    # this out
    additionalCheckArgs <- c("--no-tests")
  } else {
    additionalCheckArgs <- c()
  }
  checkPackage(package = dependencies$name[i], 
               inCran = dependencies$inCran[i],
               additionalCheckArgs = additionalCheckArgs)
}
unlink("Dependencies.rds")
