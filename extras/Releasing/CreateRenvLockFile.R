# Here we create an empty renv library, and install all of HADES. We  then 
# create an renv.lock file to capture all current versions.

# Make sure to delete renv.lock, .Rprofile, and the renv folder first

# Create an empty renv library -------------------------------------------------
renv::activate()

# Install HADES (from scratch --------------------------------------------------
install.packages("remotes")
options(install.packages.compile.from.source = "never")
remotes::install_github("ohdsi/Hades", upgrade = "never")

# This time: install soon-to-be-released DatabaseConnector version:
# remotes::install_github("ohdsi/DatabaseConnector", ref = "win_auth")


# Install additional packages sometimes needed by HADES ------------------------
packagesUtils <- c("keyring")
packagesForPlp <- c("lightgbm", "survminer", "parallel", "xgboost", "reticulate", "mgcv", "polspline")
packagesForDatabaseConnector <- c("duckdb", "RSQLite", "aws.s3", "R.utils", "odbc", "AzureStor")
packagesForKeeper <- c("ellmer", "shinyjs", "bslib",  "plotly", "pool")
additionalPackages <- c(packagesForPlp, packagesUtils, packagesForDatabaseConnector, packagesForKeeper)
install.packages(additionalPackages)

# Create renv lock file --------------------------------------------------------
# remotes::install_github("ohdsi/OhdsiRTools")
# OhdsiRTools::createRenvLockFile(
#   rootPackage = "Hades",
#   mode = "description",
#   includeRootPackage = TRUE,
#   additionalRequiredPackages = additionalPackages
# )
# Manually fix remoteRef and remoteUserName  of HADES entry!!!!
renv::snapshot(type = "all", dev = FALSE)


# Delete the renv folder and .Rprofile file, so we can build the renv library from scratch based on the new lock file

renv::init()
