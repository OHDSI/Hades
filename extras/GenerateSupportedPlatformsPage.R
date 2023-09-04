# setwd("C:/Temp/Git/Hades")
platforms <- read.csv("extras/supportedPlatforms.csv", stringsAsFactors = FALSE)
platforms <- platforms[order(platforms$platform), ]

headerFile <- "extras/supportedPlatformsHeader.Rmd"
lines <- gsub("\r", "", readChar(headerFile, file.info(headerFile)$size))
lines <- c(lines, "| Platform           | Abbreviation | Status       | Testing |")
lines <- c(lines, "| :----------------- | :----------- | :----------- |:------- |")
for (i in 1:nrow(platforms)) {
  lines <- c(lines, sprintf("| %s | %s | %s | %s |", 
							platforms$platform[i],
							platforms$abbreviation[i],
							platforms$status[i],
							platforms$testingInGithubActions[i]))
}
write(lines, "Rmd/supportedPlatforms.Rmd")
