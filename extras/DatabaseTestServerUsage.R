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
           "SQLite"),
  string = c("CDM5_POSTGRESQL_SERVER",
             "CDM5_SQL_SERVER_SERVER",
             "CDM5_ORACLE_SERVER",
             "CDM5_REDSHIFT_SERVER",
             "CDM_SNOWFLAKE_CONNECTION_STRING",
             "CDM5_SPARK_CONNECTION_STRING",
             "CDM_BIG_QUERY_CONNECTION_STRING",
             "Eunomia"),
  alternativeString = c("postgresql",
                        "sql server",
                        "oracle",
                        "redshift",
                        "snowflake",
                        "spark",
                        "bigquery",
                        "sqlite")
)

usesDatabaseConnector <- function(packageName) {
  if (packageName == "DatabaseConnector") {
    return(TRUE)
  }
  url <- sprintf("https://raw.githubusercontent.com/OHDSI/%s/main/DESCRIPTION", packageName)
  pageGet <- httr::GET(url)
  description <- httr::content(pageGet)
  return(grepl("DatabaseConnector", description))
}

listTestFiles <- function(packageName) {
  url <- sprintf("https://api.github.com/repos/ohdsi/%s/git/trees/main?recursive=1", packageName)
  auth <- httr::authenticate(Sys.getenv("GITHUB_PAT"), "x-oauth-basic", "basic")
  pageGet <- httr::GET(url, auth)
  tree <- httr::content(pageGet)$tree
  files <- sapply(tree, function(x) if (grepl("tests/testthat/.*\\.[rR]$", x$path)) return(x$path) else return(NA))
  files <- files[!is.na(files)]
  return(files)
}

loadTestFile <- function(packageName, file) {
  url <- sprintf("https://raw.githubusercontent.com/OHDSI/%s/main/%s", packageName, file)
  pageGet <- httr::GET(url)
  page <- httr::content(pageGet)
  if (is.null(page)) {
    return("")
  } else {
    return(page)
  }
}

rows <- list()
# packageName = "CohortMethod"
packageName = "DatabaseConnector"
for (packageName in hadesPackages$name) {
  message("Checking test server usage in ", packageName)
  if (!usesDatabaseConnector(packageName)) {
    serverFound <- as.logical(rep(NA, nrow(testingServers)))
  } else {
    serverFound <- rep(FALSE, nrow(testingServers))
    for (file in listTestFiles(packageName)) {
      page <- loadTestFile(packageName, file)
      serverFound <- serverFound | sapply(testingServers$string, function(string) return(grepl(string, page)[[1]]))
      serverFound <- serverFound | sapply(testingServers$alternativeString, function(string) return(grepl(string, page)[[1]]))
    }
  }
  names(serverFound) = testingServers$dbms
  row <- as_tibble(t(serverFound)) %>%
    mutate(package = packageName)
  rows[[length(rows) + 1]] <- row
}
rows <- bind_rows(rows)

saveRDS(rows, "extras/DatabaseTestServerUsage.rds")
