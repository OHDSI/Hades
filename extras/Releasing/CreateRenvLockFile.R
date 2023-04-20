# Here we create an empty renv library, and install all of HADES. We  then 
# create an renv.lock file to capture all current versions.

# Make sure to delete renv.lock, .Rprofile, and the renv folder first

# Create an empty renv library -------------------------------------------------
renv::activate()

# Install HADES (from scratch --------------------------------------------------
install.packages("remotes")
options(install.packages.compile.from.source = "never")
remotes::install_github("ohdsi/Hades")

# Create renv lock file --------------------------------------------------------
remotes::install_github("ohdsi/OhdsiRTools")

packagesUtils <- c("keyring")
packagesForPlp <- c("lightgbm", "survminer", "parallel")
packagesForBulkImport <- c("aws.s3", "R.utils")
install.packages(c(packagesForPlp, packagesUtils))

OhdsiRTools::createRenvLockFile(
  rootPackage = "Hades",
  mode = "description",
  includeRootPackage = TRUE,
  additionalRequiredPackages = c(packagesForPlp, packagesUtils, packagesForBulkImport)
)
# Manually fix remoteRef and remoteUserName  of HADES entry

renv::init()
