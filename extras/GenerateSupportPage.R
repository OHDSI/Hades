# setwd("C:/Temp/Git/Hades")
packages <- read.csv("extras/packages.csv", stringsAsFactors = FALSE)
packages <- packages[order(packages$name), ]

headerFile <- "extras/supportHeader.Rmd"
lines <- gsub("\r", "", readChar(headerFile, file.info(headerFile)$size))
for (i in 1:nrow(packages)) {
  name <- packages$name[i]
  lines <- c(lines, sprintf("- [%s issue tracker](https://github.com/OHDSI/%s/issues)", name, name))
  lines <- c(lines, "")
}
write(lines, "Rmd/support.Rmd")
