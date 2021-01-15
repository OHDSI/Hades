library(DiagrammeR)

hadesPackages <- read.csv("extras/packages.csv")



splitPackageList <- function(packageList) {
  if (is.null(packageList)) {
    return(c())
  } else {
    return(strsplit(gsub("\\([^)]*\\)", "", gsub(" ", "", gsub("\n", "", packageList))),
                    ",")[[1]])
  }
}

fetchDependencies <- function(package, recursive = TRUE, level = 0) {
  description <- packageDescription(package)
  packages <- splitPackageList(description$Depends)
  packages <- c(packages, splitPackageList(description$Imports))
  packages <- c(packages, splitPackageList(description$LinkingTo))
  # Note: if we want to include suggests, we'll need to consider circular references packages <-
  # c(packages, splitPackageList(description$Suggests))
  packages <- packages[packages != "R"]
  packages <- data.frame(name = packages, level = rep(level,
                                                      length(packages)), stringsAsFactors = FALSE)
  if (recursive && nrow(packages) > 0) {
    all <- lapply(packages$name, fetchDependencies, recursive = TRUE, level = level + 1)
    dependencies <- do.call("rbind", all)
    if (nrow(dependencies) > 0) {
      packages <- rbind(packages, dependencies)
      packages <- aggregate(level ~ name, packages, max)
    }
  }
  return(packages)
}

a_graph <- create_graph()

for (hadesPackage in hadesPackages$name) {
  a_graph <- add_node(a_graph, label = hadesPackage, node_aes = node_aes(shape = "rectangle"))
}

for (hadesPackage in hadesPackages$name) {
  dependencies <- fetchDependencies(hadesPackage, recursive = FALSE)
  dependencies <- dependencies$name[dependencies$name %in% hadesPackages$name]
  for (dependency in dependencies) {
    a_graph <- add_edge(a_graph, from = which(hadesPackages$name == hadesPackage), to = which(hadesPackages$name == dependency))
  }
}

assignedAll <- c()
x <- -300
while (length(assignedAll) != nrow(hadesPackages)) {
  assignedLevel <- c()
  y <- -350 + x %% 500 / 5
  for (hadesPackage in hadesPackages$name) {
    if (!hadesPackage %in% assignedAll) {
      dependencies <- fetchDependencies(hadesPackage, recursive = FALSE)
      dependencies <- dependencies$name[dependencies$name %in% hadesPackages$name]
      if (all(dependencies %in% assignedAll)) {
        assignedLevel <- c(assignedLevel, hadesPackage)
        a_graph <- set_node_position(a_graph, 
                          node =  which(hadesPackages$name == hadesPackage),  
                          x = x, 
                          y = y)
        y <- y + 150
      }
    }
  }
  assignedAll <- c(assignedAll, assignedLevel)
  x <- x + 250
}


render_graph(a_graph, layout = "nicely", output = "visNetwork")
render_graph(a_graph, layout = "tree", output = "visNetwork")
render_graph(a_graph, layout = "circular", output = "visNetwork")
render_graph(a_graph, layout = "kk", output = "visNetwork")
render_graph(a_graph, layout = "fr", output = "visNetwork")




