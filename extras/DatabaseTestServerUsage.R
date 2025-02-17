# For each HADES package, figure out which testing servers it uses:
library(dplyr)

hadesPackages <- readr::read_csv("extras/packages.csv", show_col_types = FALSE)

testingServers <- tibble(
  dbms = c("PostgreSQL",
           "SQL Server",
           "Oracle",
           "Redshift",
           "Snowflake",
           "Spark",
           "BigQuery",
           "SQLite",
           "InterSystems IRIS"),
  string = c("CDM5_POSTGRESQL_SERVER",
             "CDM5_SQL_SERVER_SERVER",
             "CDM5_ORACLE_SERVER",
             "CDM5_REDSHIFT_SERVER",
             "CDM_SNOWFLAKE_CONNECTION_STRING",
             "CDM5_SPARK_CONNECTION_STRING",
             "CDM_BIG_QUERY_CONNECTION_STRING",
             "Eunomia",
             "CDM_IRIS_CONNECTION_STRING"),
  alternativeString = c("postgresql",
                        "sql server",
                        "oracle",
                        "redshift",
                        "snowflake",
                        "spark",
                        "bigquery",
                        "sqlite",
                        "iris")
)

usesDatabaseConnector <- function(packageName, organization) {
  if (packageName == "DatabaseConnector") {
    return(TRUE)
  }
  url <- sprintf("https://raw.githubusercontent.com/%s/%s/main/DESCRIPTION", organization, packageName)
  pageGet <- httr::GET(url)
  description <- httr::content(pageGet)
  return(grepl("DatabaseConnector", description))
}

listTestFiles <- function(packageName, organization) {
  url <- sprintf("https://api.github.com/repos/%s/%s/git/trees/main?recursive=1", organization, packageName)
  auth <- httr::authenticate(Sys.getenv("GITHUB_PAT"), "x-oauth-basic", "basic")
  pageGet <- httr::GET(url, auth)
  tree <- httr::content(pageGet)$tree
  files <- sapply(tree, function(x) if (grepl("tests/testthat/.*\\.[rR]$", x$path)) return(x$path) else return(NA))
  files <- files[!is.na(files)]
  return(files)
}

loadTestFile <- function(packageName, organization, file) {
  url <- sprintf("https://raw.githubusercontent.com/%s/%s/main/%s", organization, packageName, file)
  pageGet <- httr::GET(url)
  page <- httr::content(pageGet)
  if (is.null(page)) {
    return("")
  } else {
    return(page)
  }
}

rows <- list()
# i = 1
for (i in seq_len(nrow(hadesPackages))) {
  package <- hadesPackages[i, ]
  message("Checking test server usage in ", package$name)
  if (!usesDatabaseConnector(package$name, package$organization)) {
    serverFound <- as.logical(rep(NA, nrow(testingServers)))
  } else {
    serverFound <- rep(FALSE, nrow(testingServers))
    for (file in listTestFiles(package$name, package$organization)) {
      page <- loadTestFile(package$name, package$organization, file)
      serverFound <- serverFound | sapply(testingServers$string, function(string) return(grepl(string, page)[[1]]))
      serverFound <- serverFound | sapply(testingServers$alternativeString, function(string) return(grepl(string, page)[[1]]))
    }
  }
  names(serverFound) = testingServers$dbms
  row <- as_tibble(t(serverFound)) %>%
    mutate(package = package$name)
  rows[[length(rows) + 1]] <- row
}
rows <- bind_rows(rows)

saveRDS(rows, "extras/DatabaseTestServerUsage.rds")
