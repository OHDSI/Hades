#' pareHades
#'
#' Runs the \link[PaRe](makeReport) for all packages specified in the
#' `extras/packages.csv` file.
#'
#' @param packagesPath (`character(1)` `"extras/packages.csv"`)\cr
#' Path to `packages.csv`.
#' 
#' @param logPath (`character(1)` `"./"`)\cr
#' Path to write log-file to.
#' 
#' @param nCores (`numeric(1)` `10`)\cr
#' Number of cores to use for palatalization.
#'
#' @return (`NULL`)
pareHades <- function(
    packagesPath = "extras/packages.csv",
    logPath = "./",
    nCores = 10) {
  start <- Sys.time()
  pkgs <- read.csv(packagesPath)
  pkgNames <- pkgs$name
  
  logFile <- file.path(
    logPath,
    sprintf("%s_pare_log.txt", as.integer(Sys.time()))
  )
  
  cl <- parallel::makeCluster(nCores)
  on.exit(parallel::stopCluster(cl))
  parallel::clusterExport(cl, "logFile", envir = environment())
  invisible(parallel::clusterEvalQ(cl, {
    library(PaRe)
    library(git2r)
  }))
  
  parallel::parLapply(cl = cl, X = pkgNames, fun = function(pkg) {
    tryCatch({
      start <- Sys.time()
      repoDir <- file.path(tempdir(), pkg)
      
      git2r::clone(
        url = sprintf("https://github.com/OHDSI/%s.git", pkg),
        local_path = repoDir
      )
      
      repo <- PaRe::Repository$new(repoDir)
      
      PaRe::makeReport(
        repo = repo,
        outputFile = file.path("extras/pare_reports/", sprintf("%s.html", pkg))
      )
      timeDiff <- round(Sys.time() - start, 2)
      write(
        x = sprintf("[*] Generated PaRe report for %s [%s %s]", pkg, as.numeric(timeDiff), units(timeDiff)),
        file = logFile,
        append = TRUE
      )
      unlink(repoDir, recursive = TRUE)
    }, error = function(e) {
      unlink(file.path(sprintf("extras/pare_reports/%s_files", pkg)), recursive = TRUE)
      unlink(file.path(sprintf("extras/pare_reports/%s.html", pkg)))
      unlink(repoDir, recursive = TRUE)
      write(
        x = sprintf("[!] Generating PaRe report for %s failed\n%s\n\n", pkg, e$message),
        file = logFile,
        append = TRUE
      )
    })
  })
  timeDiff <- round(Sys.time() - start, 2)
  message(sprintf("Wrote reports to: %s", "docs/pare_reports/"))
  message(sprintf("Time: %s %s", as.numeric(timeDiff), units(timeDiff)))
  return(NULL)
}

pareHades(logPath = "./extras/")
