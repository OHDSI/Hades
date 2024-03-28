# Code to install Python dependencies. Does not use conda as it was throwing inexplicable errors

# Install packages needed by PatientLevelPrediction ----------------------------
PatientLevelPrediction::configurePython(envname = 'r-reticulate', envtype = "python")
reticulate::use_virtualenv("r-reticulate")
# Test:  np <- reticulate::import('numpy')

# Packages needed by DeepPatientLevelPrediction --------------------------------
reticulate::py_install(c("polars", "tqdm", "connectorx", "scikit-learn", "pyarrow"))
reticulate::py_install("torch")
# Test: torch <- reticulate::import('torch')
# Error in py_module_import(module, convert = convert) : 
#   TypeError: the first argument must be callable

# PatientLevelPrediction requires Anaconda to be installed ---------------------
reticulate::install_miniconda()
# Test:
reticulate::conda_binary()

