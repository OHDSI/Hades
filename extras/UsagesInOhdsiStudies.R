library(httr)
library(dplyr)

getRepos <- function(user = NULL, password = NULL) {
  url <- "https://api.github.com/orgs/ohdsi-studies/repos"
  result <- list()
  pageNr <- 1
  writeLines(paste("- Fetching page", pageNr))
  if (is.null(user)) {
    pageGet <- httr::GET(paste0(url, "?page=", pageNr))
  } else {
    pageGet <- httr::GET(paste0(url, "?page=", pageNr), httr::authenticate(user, ))
  }
  page <- httr::content(pageGet)
  if (!is.null(page$message) && page$message == "Git Repository is empty.")
    return(result)
  while (length(page) != 0) {
    result <- append(result, page)
    pageNr <- pageNr + 1
    writeLines(paste("- Fetching page", pageNr))
    if (is.null(user)) {
      pageGet <- httr::GET(paste0(url, "?page=", pageNr))
    } else {
      pageGet <- httr::GET(paste0(url, "?page=", pageNr), httr::authenticate(user, ))
    }
    page <- httr::content(pageGet)
  }
  return(result)
}

parseRepos <- function(repos) {
  
  ignoreRepos <- c("EmptyStudyRepository", "StudyRepoTemplate")
  
  processRepo <- function(repo) {
    if (repo$name %in% ignoreRepos) {
      return(NULL)
    } else {
      return(tibble(name = repo$name,
                    createdDate = substr(repo$created_at, 1, 10),
                    lastPushDate = substr(repo$pushed_at, 1, 10)))
    }
  }
  result <- lapply(repos, processRepo)
  result <- bind_rows(result)
  return(result)
}

getAllDescriptions <- function(repoTable, user = NULL, password = NULL) {
  
  getDescriptionPaths <- function(node) {
    if (grepl("DESCRIPTION$", node$path)) {
      return(tibble(path = node$path))
    } else {
      return(NULL)
    }
  }
  
  loadFile <- function(repoName, path, user, password) {
    url <- sprintf("https://raw.githubusercontent.com/ohdsi-studies/%s/master/%s", repoName, path)
    if (is.null(user)) {
      pageGet <- httr::GET(url)
    } else {
      pageGet <- httr::GET(url, httr::authenticate(user, password))
    }
    return(httr::content(pageGet))
  }
  
  getDescriptions <- function(repoName, user, password) {
    writeLines(paste("Search for DESCRIPTION files in ", repoName))
    url <- sprintf("https://api.github.com/repos/ohdsi-studies/%s/git/trees/master?recursive=1", repoName)
    if (is.null(user)) {
      pageGet <- httr::GET(url)
    } else {
      pageGet <- httr::GET(url, httr::authenticate(user, password))
    }
    tree <- httr::content(pageGet)$tree
    descriptionPaths <- lapply(tree, getDescriptionPaths)
    descriptionPaths <- bind_rows(descriptionPaths)
    if (nrow(descriptionPaths) == 0) {
      return(NULL)
    } else {
      descriptionPaths$description <- sapply(descriptionPaths$path, loadFile, repoName = repoName, user = user, password = password)
      descriptionPaths$repoName <- rep(repoName, nrow(descriptionPaths))
      return(descriptionPaths)
    }
  }
  
  result <- lapply(repoTable$name, getDescriptions, user = user, password = password)
  result <- bind_rows(result)
  return(result)
}

findHadesPackages <- function(descriptions) {

  findHadesNames <- function(description, hadesNames) {
     
  }
    
  hadesPackages <- readr::read_csv("extras/packages.csv")
  hadesNames <- hadesPackages$name
   
}

repos <- getRepos(user = user, password = password)
repoTable <- parseRepos(repos)
descriptions <- getAllDescriptions(repoTable, user = user, password = password)

repoTable %>%
  anti_join(descriptions, by = c("name" = "repoName"))

findHadesPackages(descriptions)

repoTable <- parseReadmes(repoTable)

repoTable$timeStamp <- Sys.time()
saveRDS(repoTable, "c:/temp/repoTable.rds")


