# To verify: run R check on each HADES package 

install.packages("rcmdcheck")

reticulate::use_virtualenv("r-reticulate")

source("PackageCheckFunctions.R")
saveRDS(prepareForPackageCheck(), "Dependencies.rds")
dependencies <- readRDS("Dependencies.rds")
# Skipping Hydra, as renv seems to clash with skeleton renv environments:
dependencies <- dependencies[dependencies$name != "Hydra", ]
for (i in 1:nrow(dependencies)) {
  if (dependencies$name[i] == "PatientLevelPrediction") {
    # Temp workaround for https://github.com/OHDSI/PatientLevelPrediction/issues/435
    additionalCheckArgs <- c("--no-build-vignettes", "--ignore-vignettes")
  } else {
    additionalCheckArgs <- c()
  }
  checkPackage(package = dependencies$name[i], 
               inCran = dependencies$inCran[i],
               additionalCheckArgs = additionalCheckArgs)
}
unlink("Dependencies.rds")
