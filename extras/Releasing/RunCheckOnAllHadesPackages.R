# To verify: run R check on each HADES package 

install.packages("rcmdcheck")

source("PackageCheckFunctions.R")
saveRDS(prepareForPackageCheck(), "Dependencies.rds")
dependencies <- readRDS("Dependencies.rds")
# Skipping Hydra, as renv seems to clash with skeleton renv environments:
dependencies <- dependencies[dependencies$name != "Hydra", ]
for (i in 25:nrow(dependencies)) {
  if (dependencies$name[i] == "CohortGenerator") {
    # Delete RedShift files from JDBC drivers folder, at least until this is released: https://github.com/OHDSI/DatabaseConnector/commit/c7e3e9b8dab2b04bebadfcf34f2049a23de66dac
    toDelete <- list.files(Sys.getenv("DATABASECONNECTOR_JAR_FOLDER"), "Redshift", full.names = TRUE)
    unlink(toDelete, force = TRUE)
  }
  checkPackage(package = dependencies$name[i], inCran = dependencies$inCran[i])
}
unlink("Dependencies.rds")
