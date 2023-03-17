# To verify: run R check on each HADES package ---------------------------------

install.packages("rcmdcheck")

source("PackageCheckFunctions.R")
saveRDS(prepareForPackageCheck(), "Dependencies.rds")
dependencies <- readRDS("Dependencies.rds")
# Skipping Hydra, as renv seems to clash with skeleton renv environments:
dependencies <- dependencies[dependencies$name != "Hydra", ]
for (i in 11:nrow(dependencies)) {
  if (dependencies$name == "CohortGenerator") {
    # TODO: delete RedShift files from JDBC drivers folder, at least until this is released: https://github.com/OHDSI/DatabaseConnector/commit/c7e3e9b8dab2b04bebadfcf34f2049a23de66dac
    
  }
  checkPackage(package = dependencies$name[i], inCran = dependencies$inCran[i])
}
unlink("ReverseDependencyCheckFunctions.R")
unlink("reverseDependencies.rds")