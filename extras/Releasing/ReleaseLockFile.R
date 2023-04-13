creationTime <- file.info("renv.lock")$ctime

folder <- file.path("..", "..", "hadesWideReleases", format(creationTime,"%Y%b%d"))
dir.create(folder)
file.copy(from = "renv.lock", to = folder)
                    