# Unit tests on CohortDiagnostics using testing servers take too long, so using local 
# Postgres server
library(dplyr)
library(Capr)

connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",
  user = Sys.getenv("LOCAL_POSTGRES_USER"),
  password = Sys.getenv("LOCAL_POSTGRES_PASSWORD"),
  server = Sys.getenv("LOCAL_POSTGRES_SERVER")
)
cdmDatabaseSchema <- Sys.getenv("LOCAL_POSTGRES_CDM_SCHEMA")
cohortDatabaseSchema <- Sys.getenv("LOCAL_POSTGRES_OHDSI_SCHEMA")
cohortTable <- "cd_test"
folder <- "e:/temp/cdOutput"

# Create cohorts using Capr ----------------------------------------------------
osteoArthritisOfKneeConceptId <- 4079750
celecoxibConceptId <- 1118084
diclofenacConceptId <- 1124300
osteoArthritisOfKnee <- cs(
  descendants(osteoArthritisOfKneeConceptId),
  name = "Osteoarthritis of knee"
)
attrition = attrition(
  "prior osteoarthritis of knee" = withAll(
    atLeast(1, conditionOccurrence(osteoArthritisOfKnee), duringInterval(eventStarts(-Inf, 0)))
  )
)
celecoxib <- cs(
  descendants(celecoxibConceptId),
  name = "Celecoxib"
)
diclofenac  <- cs(
  descendants(diclofenacConceptId),
  name = "Diclofenac"
)
celecoxibCohort <- cohort(
  entry = entry(
    drugExposure(celecoxib, firstOccurrence()),
    observationWindow = continuousObservation(priorDays = 365)
  ),
  # attrition = attrition,
  exit = exit(endStrategy = drugExit(celecoxib,
                                     persistenceWindow = 30,
                                     surveillanceWindow = 0))
)
diclofenacCohort <- cohort(
  entry = entry(
    drugExposure(diclofenac, firstOccurrence()),
    observationWindow = continuousObservation(priorDays = 365)
  ),
  # attrition = attrition,
  exit = exit(endStrategy = drugExit(diclofenac,
                                     persistenceWindow = 30,
                                     surveillanceWindow = 0))
)
cohortDefinitionSet <- Capr::makeCohortSet(celecoxibCohort, diclofenacCohort)

# Generate cohorts -------------------------------------------------------------
cohortTableNames <- CohortGenerator::getCohortTableNames(cohortTable = cohortTable)
CohortGenerator::createCohortTables(
  connectionDetails = connectionDetails,
  cohortTableNames = cohortTableNames,
  cohortDatabaseSchema = cohortDatabaseSchema,
  incremental = FALSE
)
CohortGenerator::generateCohortSet(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortDatabaseSchema = cohortDatabaseSchema,
  cohortTableNames = cohortTableNames,
  cohortDefinitionSet = cohortDefinitionSet,
  incremental = FALSE
)
CohortGenerator::getCohortCounts(connectionDetails = connectionDetails,
                                 cohortDatabaseSchema = cohortDatabaseSchema,
                                 cohortTable = cohortTable)

# Run CohortDiagnostics --------------------------------------------------------
dir.create(folder)

cohortDefinitionSet$cohortId <- as.double(cohortDefinitionSet$cohortId)
CohortDiagnostics::executeDiagnostics(
  cohortDefinitionSet = cohortDefinitionSet,
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortDatabaseSchema = cohortDatabaseSchema,
  cohortTable = cohortTable,
  cohortIds = cohortDefinitionSet$cohortId,
  exportFolder = file.path(folder, "export"),
  databaseId = "Synpuf",
  runInclusionStatistics = TRUE,
  runBreakdownIndexEvents = TRUE,
  runTemporalCohortCharacterization = TRUE,
  runIncidenceRate = TRUE,
  runIncludedSourceConcepts = TRUE,
  runOrphanConcepts = TRUE,
  runTimeSeries = TRUE,
  runCohortRelationship = TRUE,
  minCellCount = 5,
)

file.exists(file.path(
  folder, "export", paste0("Results_Synpuf.zip")
))
