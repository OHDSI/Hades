Creating a HADES-wide release
=============================

Here you'll find the scripts used to create HADES-wide releases. A HADES-wide release is a snapshot of HADES and all of its dependencies at a specific point in time, and can form the stable basis for study packages, etc.

The following R code is executed in order:

1. **CreateRenvLockFile.R** is used to create the renv lock file for all of HADES and its dependencies.
2. **SetupPython.R** prepares Python for running those unit tests that require Python.
3. **RunCheckOnAllHadesPackages.R** runs R check on each HADES package using the renv lock file, to ensure it is complete, and all HADES packages work with the dependencies captured in the lock file.
4. **ReleaseLockFile.R** copy the lock file into the `/hadesWideReleases` folder. The subfolder will be named after the date the renv lock file was created.


