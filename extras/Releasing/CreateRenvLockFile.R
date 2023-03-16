# Create an empty renv library -------------------------------------------------
renv::activate()

# Install HADES (from scratch --------------------------------------------------
install.packages("remotes")
options(install.packages.compile.from.source = "never")
remotes::install_github("ohdsi/Hades")

# Create renv lock file --------------------------------------------------------
remotes::install_github("ohdsi/OhdsiRTools")
OhdsiRTools::createRenvLockFile(
  rootPackage = "Hades",
  mode = "description",
  includeRootPackage = TRUE,
  additionalRequiredPackages = c("keyring")
)

renv::init()