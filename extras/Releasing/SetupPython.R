# Code to install Python dependencies. Does not use conda as it was throwing inexplicable errors

# Install packages needed by PatientLevelPrediction ----------------------------
PatientLevelPrediction::configurePython(envname = 'r-reticulate', envtype = "python")
reticulate::use_virtualenv("r-reticulate")
# Test:  np <- reticulate::import('numpy')

# Packages needed by DeepPatientLevelPrediction --------------------------------
reticulate::py_install(c("polars", "tqdm", "connectorx", "scikit-learn", "pyarrow"))
reticulate::py_install("torch")
# Test: torch <- reticulate::import('torch')
pyarrow <- reticulate::import('pyarrow')

# reticulate::virtualenv_remove("r-reticulate")

reticulate::virtualenv_list()
reticulate::virtualenv_root()
