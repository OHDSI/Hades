# Code to work around renv bugs relating to Python

# Install all required dependencies --------------------------------------------
packages <- c("scikit-survival","numpy","scipy","scikit-learn", "pandas","pydotplus","joblib", "sklearn-json")
reticulate::conda_install(
  envname='base', 
  packages = packages, 
  forge = TRUE, 
  pip = FALSE, 
  pip_ignore_installed = TRUE, 
  conda = "auto"
)
reticulate::conda_install(
  envname='r-reticulate', 
  packages = packages, 
  forge = TRUE, 
  pip = FALSE, 
  pip_ignore_installed = TRUE, 
  conda = "auto"
  )
reticulate::use_condaenv("base")
torch::install_torch()
reticulate::use_condaenv("r-reticulate")
torch::install_torch()

# Copy Python from global to renv ----------------------------------------------

# Under some (poorly understood) circumstances, reticulate creates a duplicate
# r-reticulate environment. Use this code to copy all libraries from the main one
# to the new one:
envs <- reticulate::conda_list()
envs <- envs[envs$name == 'r-reticulate', ]
message(sprintf("Good r-reticulate: %s", envs$python[1]))
message(sprintf("Evil r-reticulate: %s", envs$python[2]))
# TODO: this somehow creates a r-reticulate folder in the r-reticulate folder. Need to fix
unlink(dirname(envs$python[2]), recursive = TRUE)
dir.create(dirname(envs$python[2]))
file.copy(
  from = dirname(envs$python[1]),
  to = dirname(envs$python[2]),
  recursive = TRUE
)