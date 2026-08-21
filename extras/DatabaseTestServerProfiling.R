platforms <- read.csv("c:/git/ohdsi/Hades/extras/supportedPlatforms.csv", stringsAsFactors = FALSE)
platforms <- platforms[order(platforms$platform), ]
ghaPlatforms <- platforms[platforms$testingInGithubActions == 'Yes', ]

# DatabaseConnector::downloadJdbcDrivers(
#   dbms = "all"
# )

empty_value <- function(x) {
  if (inherits(x, "Date")) {
    as.Date(NA)
  } else if (is.numeric(x)) {
    NA_real_
  } else if (is.integer(x)) {
    NA_integer_
  } else if (is.logical(x)) {
    NA
  } else {
    "EMPTY"
  }
}

dbInfo <- tibble::tibble()
for (i in seq_len(nrow(ghaPlatforms))) {
  dbms <- ghaPlatforms$abbreviation[i]
  dbmsFormatted <- toupper(gsub(" ", "_", dbms))
  cli::cli_inform(dbms)
  # HACK for big query
  if (dbms == "bigquery") {
    dbmsFormatted = "BIG_QUERY"
  }
  # HACK for key
  if (dbms %in% c("bigquery", "snowflake", "iris")) {
    keyPrefix = "CDM_"
  } else {
    keyPrefix = "CDM5_"
  }

  userKey <- paste0(keyPrefix, dbmsFormatted, "_USER")
  passwordKey <- paste0(keyPrefix, dbmsFormatted, "_PASSWORD")
  serverKey <- paste0(keyPrefix, dbmsFormatted, "_SERVER")
  connectionStringKey <- paste0(keyPrefix, dbmsFormatted, "_CONNECTION_STRING")
  cdmSchemaKey <- paste0(keyPrefix, dbmsFormatted, "_CDM_SCHEMA")

  # HACK For Snowflake
  if (dbms == "snowflake") {
    cdmSchemaKey <- paste0(keyPrefix, dbmsFormatted, "_CDM53_SCHEMA")
  }

  if (Sys.getenv(serverKey) == "" && Sys.getenv(connectionStringKey) == "") {
    cli::cli_alert_warning("Skipping - no server/connection info found")
    next
  }

  if (tolower(dbms) == "bigquery") {
      bqKeyFile <- tempfile(fileext = ".json")
      writeLines(Sys.getenv("CDM_BIG_QUERY_KEY_FILE"), bqKeyFile)
      bqConnectionString <- gsub(
        "<keyfile path>",
        normalizePath(bqKeyFile, winslash = "/"),
        Sys.getenv("CDM_BIG_QUERY_CONNECTION_STRING")
      )
      connectionDetails <- DatabaseConnector::createConnectionDetails(
        dbms = "bigquery",
        user = "",
        password = "",
        connectionString = !!bqConnectionString
      )
  } else if (Sys.getenv(connectionStringKey) != "") {
    connectionDetails <- DatabaseConnector::createConnectionDetails(
      dbms = dbms,
      user = Sys.getenv(userKey),
      password = URLdecode(Sys.getenv(passwordKey)),
      connectionString = Sys.getenv(connectionStringKey)
    )
  } else {
    connectionDetails <- DatabaseConnector::createConnectionDetails(
      dbms = dbms,
      user = Sys.getenv(userKey),
      password = URLdecode(Sys.getenv(passwordKey)),
      server = Sys.getenv(serverKey)
    )
  }
  connection <- DatabaseConnector::connect(connectionDetails)
  getCdmSourceInfoSql <- "SELECT * FROM @cdm_schema.cdm_source;"

  cdmSourceInfo <- DatabaseConnector::renderTranslateQuerySql(
    connection = connection,
    sql = getCdmSourceInfoSql,
    cdm_schema = Sys.getenv(cdmSchemaKey)
  )

  names(cdmSourceInfo) <- tolower(names(cdmSourceInfo))

  if (nrow(cdmSourceInfo) == 0) {
   cdmSourceInfo <- dplyr::bind_rows(
      cdmSourceInfo,
      tibble::as_tibble_row(purrr::map(cdmSourceInfo, empty_value))
    )   
  }

  getCdmPersonCountSql <- "SELECT COUNT(*) person_cnt FROM @cdm_schema.person;"
  totalPersonCount <- DatabaseConnector::renderTranslateQuerySql(
    connection = connection,
    sql = getCdmPersonCountSql,
    cdm_schema = Sys.getenv(cdmSchemaKey)
  )
  names(totalPersonCount) <- tolower(names(totalPersonCount))

  getObsPeriodRangeSql <- "
    SELECT 
      MIN(observation_period_start_date) obs_period_start_date
      , MAX(observation_period_end_date) obs_period_end_date
      FROM @cdm_schema.observation_period;
  "

  obsPeriodRange <- DatabaseConnector::renderTranslateQuerySql(
    connection = connection,
    sql = getObsPeriodRangeSql,
    cdm_schema = Sys.getenv(cdmSchemaKey)
  )
  names(obsPeriodRange) <- tolower(names(obsPeriodRange))

  DatabaseConnector::disconnect(connection)
  curDbInfo <- cbind(data.frame(dbms = c(dbms), cdmSourceInfo, totalPersonCount, obsPeriodRange))
  dbInfo <- dplyr::bind_rows(
    dbInfo,
    curDbInfo
  )
}

dbInfo