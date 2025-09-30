# To verify: run R check on each HADES package 

install.packages("rcmdcheck")

# Needed to avoid 
# https://github.com/rstudio/rstudio/issues/15805
# https://github.com/r-lib/sessioninfo/issues/122
remotes::install_github("r-lib/sessioninfo")

reticulate::use_virtualenv("r-reticulate")

source("PackageCheckFunctions.R")
saveRDS(prepareForPackageCheck(), "Dependencies.rds")
dependencies <- readRDS("Dependencies.rds")
dependencies <- dependencies[!dependencies$deprecated, ]
# dependencies <- dependencies |>
  # dplyr::filter(!name %in% c("CohortGenerator"))
for (i in 1:nrow(dependencies)) {
  # if (dependencies$name[i] == "DeepPatientLevelPrediction") {
  #   # This package is failing unit tests, it seems because Python modules are 
  #   # missing. Skipping for now. Hoping DeepPlp users are savy enough to figure
  #   # this out
  #   additionalCheckArgs <- c("--no-tests")
  # } else {
    additionalCheckArgs <- c()
  # }
  checkPackage(package = dependencies$name[i], 
               inCran = dependencies$inCran[i],
               additionalCheckArgs = additionalCheckArgs)
}

# DeepPatientLevelPrediction: ModuleNotFoundError: No module named 'polars' 
unlink("Dependencies.rds")
