library(httr)
library(jsonlite)
library(dplyr)

cacheFolder <- "e:/temp/issueCache"

# Fetch all issues and comments for all HADES repos ----------------------------
issueToRow <- function(issue) {
  row <- tibble(
    number = issue$number,
    title = issue$title,
    body = sprintf("%s:\n%s", issue$user$login, issue$body),
    closed = issue$state == "closed",
    dateCreated = as.Date(gsub("T.*$", "", issue$created_at)),
    dateUpdated = as.Date(gsub("T.*$", "", issue$updated_at)),
    dateClosed = if (is.null(issue$closed_at)) as.Date(NA) else as.Date(gsub("T.*$", "", issue$closed_at))
  )
  return(row)
}

# Function to get all issues (open and closed) from a GitHub repository
getIssuesFromRepo <- function(repo, token) {
  url <- paste0("https://api.github.com/repos/ohdsi/", repo, "/issues?state=all&per_page=100")
  issues <- list()
  
  # Paginate through all issues
  while(!is.null(url)) {
    response <- GET(url, add_headers(Authorization = paste("token", token)))
    
    if(status_code(response) != 200) {
      stop("Failed to fetch data from GitHub API. Status code: ", status_code(response))
    }
    
    issuesPage <- content(response, as = "parsed", type = "application/json")
    issues <- append(issues, lapply(issuesPage, issueToRow))
    
    # Check for pagination and extract the next URL if available
    url <- headers(response)$`link`
    if(!is.null(url)) {
      nextLink <- gsub(".*<(.*)>; rel=\"next\".*", "\\1", url)
      if (nextLink == url) {
        url <- NULL
      } else {
        url <- nextLink
      }
    }
  }
  issues <- bind_rows(issues) |>
    mutate(repo = !!repo)
  return(issues)
}

# Function to extract all messages (comments) from a particular issue
getIssueComments <- function(repo, issue_number, token) {
  url <- paste0("https://api.github.com/repos/ohdsi/", repo, "/issues/", issue_number, "/comments")
  response <- GET(url, add_headers(Authorization = paste("token", token)))
  
  if(status_code(response) != 200) {
    stop("Failed to fetch issue comments. Status code: ", status_code(response))
  }
  
  comments <- content(response, as = "parsed", type = "application/json")
  if (length(comments) == 0) {
    return("")
  } else {
    text <- sapply(comments, function(x) sprintf("%s:\n%s", x$user$login, x$body))
    text <- paste(text, collapse = "\n\n")
    return(text)
  }
}

# Main function to fetch all issues and comments for a list of repositories
fetchAllIssuesAndComments <- function(repositories, token, cacheFolder) {
  if (!dir.exists(cacheFolder))
    dir.create(cacheFolder, recursive = TRUE)
  results <- list()
  
  for (repo in repositories) {
    fileName <- file.path(cacheFolder, sprintf("issues_%s.rds", repo))
    if (file.exists(fileName)) {
      issues <- readRDS(fileName)
    } else {
      cat("Fetching issues for repo:", repo, "\n")
      issues <- getIssuesFromRepo(repo, token)
      issues <- issues |>
        mutate(comments = "")
      for (i in seq_len(nrow(issues))) {
        issue <- issues[i, ]
        issue_number <- issue$number
        issues$comments[i] <- getIssueComments(repo, issue_number, token)
      }
      saveRDS(issues, fileName)
    }
    results[[repo]] <- issues
  }
  results <- bind_rows(results)
  return(results)
}

# repositories <- c("SelfControlledCaseSeries", "CohortMethod")
repositories <- readr::read_csv("extras/packages.csv")
issues <- fetchAllIssuesAndComments(repositories$name, Sys.getenv("GITHUB_PAT"), cacheFolder)
saveRDS(issues, file.path(cacheFolder, "allIssues.rds"))


# Analyze issues with comments using GPT-4o ------------------------------------
getGpt4Response <- function(systemPrompt, prompt) {
  json <- jsonlite::toJSON(
    list(
      messages = list(
        list(
          role = "system",
          content = systemPrompt
        ),
        list(
          role = "user",
          content = prompt
        ),
        list(
          role = "assistant",
          content = ""
        )
      )
    ),
    auto_unbox = TRUE
  )
  
  response <- POST(
    url = keyring::key_get("genai_gpt4o_endpoint"),
    body = json,
    add_headers("Content-Type" = "application/json",
                "api-key" = keyring::key_get("genai_api_gpt4_key"))
  )
  result <- content(response, "text", encoding = "UTF-8")
  result <- jsonlite::fromJSON(result)
  text <- result$choices$message$content
  return(text)
}

issues <- readRDS(file.path(cacheFolder, "allIssues.rds"))

systemPrompt <- "You are an expert in health analytics and data platforms with a focus on identifying developer burden related to specific database and query engines. Your goal is to classify issues by their relevance to specific platforms such as bigquery, duckdb, oracle, postgresql, redshift, snowflake, spark (including DataBricks), sql server, sqlite, and synapse. Be aware that in HADES packages all source SQL lives in the `inst/sql/sql_server` folder, from where it is translated, so only a mention of the `inst/sql/sql_server` folder does not imply SQL Server is involved. Additionally, you must determine whether each issue would have been raised if the platform in question was not supported. Your responses should be concise, and fit the exact specified output format so it can be parsed."


promptTemplate <- '
You are given an issue from the OHDSI Health-Analytics-Data-to-Evidence Suite (HADES) repositories. Based on the issue title, body, and comments, please answer the following:

### Issue Information:
--- Title start
%s
--- Title end

--- Body start
%s
--- Body end

--- Comments start
%s
--- Comments End

### Questions:
1. **Platform Relevance**: Which platform(s) is directly relevant to this issue? Choose from the following: bigquery, duckdb, oracle, postgresql, redshift, snowflake, spark (includes DataBricks), sql server, sqlite, synapse, or "none" if it is not platform-specific.
   
2. **Necessity of Platform Support**: Would this issue have been raised if the platform(s) identified above was/were not supported? Answer "yes" or "no" and provide a brief explanation.

### Expected Output Format:
{
  "platforms": ["{platform1}", "{platform2}", ...], 
  "would_exist_without_platform": "yes/no"
}
'

gpt4CacheFolder <- file.path(cacheFolder, "gpt4Responses")
dir.create(gpt4CacheFolder)
pb <- txtProgressBar(style = 3)
for (i in seq_len(nrow(issues))) {
  issue <- issues[i, ]
  fileName <- file.path(gpt4CacheFolder, sprintf("%s_issue%s.txt", issue$repo, issue$number))
  if (file.exists(fileName)) {
    response <- paste(readLines(fileName), collapse = "\n")
  } else {
    prompt <- sprintf(promptTemplate, issue$title, issue$body, issue$comments)
    response <- getGpt4Response(systemPrompt, prompt)
    writeLines(response, fileName)
  }
  response <- gsub("}.*", "}", gsub("```", "", gsub("```json", "", response)))
  parsed <- jsonlite::fromJSON(response)
  platforms <- gsub(" \\(includes DataBricks\\)", "", paste(parsed$platforms, collapse = ";"))
  issues$platforms[i] <- platforms
  issues$existWithoutPlatform[i] <- parsed$would_exist_without_platform == "yes"
  setTxtProgressBar(pb, i / nrow(issues))
}
close(pb)

issues <- issues |>
  select(repo, number, closed, dateCreated, dateUpdated, dateClosed, platforms, existWithoutPlatform)
saveRDS(issues, file.path(cacheFolder, "allIssuesWithPlatforms.rds"))


# Compute numbers per platform and repo ----------------------------------------
issues <- readRDS(file.path(cacheFolder, "allIssuesWithPlatforms.rds"))

platforms <- readr::read_csv("extras/supportedPlatforms.csv")
platforms <- platforms |>
  filter(status == "Supported") |>
  pull("abbreviation")
counts <- list()
for (i in seq_along(platforms)) {
  platform <- platforms[i]
  counts[[i]] <- issues |>
    filter(grepl(platform, platforms),
           existWithoutPlatform == FALSE) |>
    group_by(repo) |>
    summarise(issues = n()) |>
    mutate(platform = !!platform)
}
counts <- bind_rows(counts)

counts |>
  group_by(platform) |>
  summarise(issues = sum(issues)) |>
  arrange(desc(issues)) |>
  readr::write_csv(file.path(cacheFolder, "CountsPerPlatform.csv"))

counts |>
  arrange(platform, desc(issues)) |>
  print(n=200)

issues |>
  group_by(repo) |>
  summarise(issues = n(),
            platformIssues = sum(!existWithoutPlatform)) |>
  mutate(fraction = platformIssues / issues) |>
  arrange(desc(platformIssues)) |>
  readr::write_csv(file.path(cacheFolder, "CountsPerRepo.csv"))
