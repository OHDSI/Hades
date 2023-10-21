# Returns the list of reverse dependencies, and installs all dependencies of those packages
prepareForPackageCheck <- function() {
  packageListUrl <- "https://raw.githubusercontent.com/OHDSI/Hades/main/extras/packages.csv"
  gitHubOrganization <- "ohdsi"
  hadesPackageList <- read.table(packageListUrl, sep = ",", header = TRUE) 
  
  dependencies <- lapply(hadesPackageList$name, getPackageDependenciesFromGitHub)
  dependencies <- do.call(rbind, dependencies)
  hadesDependencies <- dependencies[dependencies$dependency %in% hadesPackageList$name & 
                                      dependencies$type != "Suggests", ]
  

  # Includes suggests of packages to check, but not suggests of deeper dependencies:
  packagesToInstall <- unique(dependencies$dependency)
  packagesToInstall <- c(packagesToInstall, "formatR") # Required for some vignettes
  # Don't install packages that are already installed:
  packagesToInstall <- packagesToInstall[!packagesToInstall %in% rownames(installed.packages())]
  
  if (length(packagesToInstall) > 0) {
    remotes::install_cran(packagesToInstall)
  }
  return(hadesPackageList)
}

#   for (package in reverseDependencies) {
#     if (hadesPackageList$inCran[hadesPackageList$name == package]) {
#       source <- "CRAN"
#     } else {
#       source <- "GitHub"
#     }
#     checkPackage(package, source)
#   }
# }

checkPackage <- function(package, inCran) {
  writeLines(sprintf("*** Checking package '%s' ***", package))
  gitHubOrganization <- "ohdsi"
  if (inCran) {
    sourcePackage <- remotes::download_version(package, type = "source")
    on.exit(unlink(sourcePackage))
  } else {
    ref <- sprintf("v%s", packageVersion(package))
    sourcePackage <- remotes::remote_download(remotes::github_remote(repo = sprintf("%s/%s", gitHubOrganization, package), ref = ref))
    on.exit(unlink(sourcePackage))
  } 
  sourceFolder <- tempfile(pattern = package)
  dir.create(sourceFolder)
  on.exit(unlink(sourceFolder, recursive = TRUE), add = TRUE)
  untar(sourcePackage, exdir = sourceFolder)
  sourcePath <- list.dirs(sourceFolder, full.names = TRUE, recursive = FALSE)
  docDir <- file.path(sourcePath, "inst", "doc")
  if (dir.exists(docDir)) {
    unlink(docDir, recursive = TRUE)
  }
  # devtools::check_built(path = sourcePath)
  rcmdcheck::rcmdcheck(path = sourcePath, args = c("--no-manual", "--no-multiarch"), error_on = "warning")
}

getPackageDependenciesFromGitHub <- function(package) {
  descriptionUrlTemplate <- "https://raw.githubusercontent.com/OHDSI/%s/main/DESCRIPTION"
  
  description <- scan(sprintf(descriptionUrlTemplate, package), what = character(), sep = "|", quiet = TRUE) 
  dependencies <- lapply(X = c("Depends", "Imports", "LinkingTo", "Suggests"), 
                         FUN = extractDependenciesFromDescriptionSection, 
                         description = description)
  dependencies <- do.call(rbind, dependencies)
  dependencies <- dependencies[dependencies$dependency != "R", ]
  coreRPackages <- rownames(installed.packages(priority = "base"))
  dependencies <- dependencies[!dependencies$dependency %in% coreRPackages, ]
  dependencies$package <- rep(package, nrow(dependencies))
  return(dependencies)
}

extractDependenciesFromDescriptionSection <- function(section, description) {
  tagsPos <- grep(":", description)
  sectionPos <- grep(sprintf("%s:", section), description)
  if (length(sectionPos) != 0) {
    endOfSection <- ifelse(sectionPos < max(tagsPos), min(tagsPos[tagsPos > sectionPos]), length(description) + 1)
    dependencies <- gsub("[\t ,]|(\\(.*\\))", "", gsub(sprintf("%s:", section), "", description[sectionPos:(endOfSection - 1)]))
    dependencies <- dependencies[dependencies != ""]
    if (length(dependencies) > 0) {
      return(data.frame(type = section,
                        dependency = dependencies))
    } 
  }
  return(NULL)
}
