
outputFolder <- "e:/HadesCheck"
options(install.packages.check.source = "no")


install.packages("devtools")

if (!file.exists(outputFolder)) {
  dir.create(outputFolder, recursive = TRUE)
}

# Hidden dependencies:
install.packages("formatR") # Used for vignettes with tidy = TRUE
# Make sure to install required LaTeX packages for FeatureExtraction

checkOhdsiPackage <- function(packageName) {
  repoName <- paste("ohdsi", packageName, sep = "/")
  checkFileName <- file.path(outputFolder, sprintf("Check_%s.txt", packageName))
  
  writeLines(sprintf("Downloading package %s", packageName))
  # source <- remotes:::remote_download(remotes:::github_remote(repoName, ref = "develop"))
  source <- remotes:::remote_download(remotes:::github_remote(repoName))
  
  writeLines(sprintf("Installing package %s", packageName))
  devtools::install_local(source, dependencies = TRUE, upgrade = "never")
  
  writeLines(sprintf("Checking package %s. Results will be written to %s", packageName, checkFileName))
  capture.output(
    devtools::check(remotes:::source_pkg(source), cran = TRUE, clean_doc = TRUE),
    file = checkFileName)
  return(NULL)
}
packageNames <- c("SqlRender", 
                  "DatabaseConnectorJars", 
                  "DatabaseConnector", 
                  "ParallelLogger", 
                  "EmpiricalCalibration", 
                  "EvidenceSynthesis", 
                  "Cyclops",
                  "FeatureExtraction", 
                  "MethodEvaluation", 
                  "CohortMethod", 
                  "SelfControlledCaseSeries",
                  "SelfControlledCohort",
                  "CaseControl",
                  "CaseCrossover",
                  "PatientLevelPrediction",
                  "ROhdsiWebApi",
                  "CohortDiagnostics",
                  "PheValuator",
                  "BigKnn",
                  "OhdsiSharing",
                  "DataQualityDashboard")


dummy <- lapply(packageNames[16:21], checkOhdsiPackage)


