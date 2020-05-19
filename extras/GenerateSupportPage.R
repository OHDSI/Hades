setwd("C:/Git/Hades")
packages <- read.csv("extras/packages.csv", stringsAsFactors = FALSE)

headerFile <- "extras/supportHeader.Rmd"
lines <- gsub("\r", "", readChar(headerFile, file.info(headerFile)$size))
for (i in 1:nrow(packages)) {
  name <- packages$name[i]
  lines <- c(lines, sprintf("- [%s issue tracker](https://github.com/OHDSI/%s/issues)", name, name))
  lines <- c(lines, "")
}
write(lines, "support.Rmd")
