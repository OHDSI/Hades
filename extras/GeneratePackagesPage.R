packages <- read.csv("extras/packages.csv", stringsAsFactors = FALSE)
headerFile <- "extras/packagesHeader.Rmd"
lines <- gsub("\r", "", readChar(headerFile, file.info(headerFile)$size))
lines <- c(lines, "")
section <- ""
for (i in 1:nrow(packages)) {
  if (packages$section[i] != section) {
    section <- packages$section[i]
    lines <- c(lines, "</ul>")
    lines <- c(lines,sprintf("<h2 id=\"pkg_header\">%s</h2>", section))
    if (grepl("Deprecated", section)) {
      lines <- c(lines, "<p style=\"text-align: center\">These packages will be removed from Hydra at the next major release</p>")
    }
    lines <- c(lines, "<ul id=\"pkg\">")
  }
  name <- packages$name[i]
  organization <- packages$organization[i]
  pd <- packages$description[i]
  if (packages$pages[i]) {
    url <- sprintf("https://%s.github.io/%s", organization, name)
  } else {
    url <- sprintf("https://github.com/%s/%s", organization, name)
  }
  lines <- c(lines, sprintf("<li><h4><i class=\"fas  fa-cube \"></i> <a href=\"%s\">%s</a></h4>%s</br><a href=\"%s\">Learn more...</a></li>",
                            url, name, pd, url))
}
lines <- c(lines, "</ul>")
write(lines, "Rmd/packages.Rmd")
