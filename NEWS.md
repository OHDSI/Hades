HADES 1.19.0
============

- PatientLevelPrediction and SelfControlledCaseSeries are now in CRAN. Removing reference to Github repos. 
- Deprecating `Hydra` because people should no longer use it. `Strategus` is the preferred method for running full studies.
- Deprecating `ShinyAppBuilder` because it has been renamed to `OhdsiShinyAppBuilder`, but some HADES packages still need to be updated to use the new name.

Deprecation means:
- The packages are moved from the *Imports* to the *Suggests* section, and will therefore no longer automatically be installed when the `Hades` package is installed.
- On the [HADES website](https://ohdsi.github.io/Hades), the packages are marked as 'Deprecated', and listed in the 'Deprecated packages' section.

HADES 1.18.0
============

- Adding OhdsiReportGenerator and OhdsiShinyAppBuilder packages. The latter will eventually replace ShinyAppBuilder when no HADES package depends on it anymore.
- Updating Characterization, which is now in CRAN. 


HADES 1.17.0
============

- Adding TreatmentPatterns to HADES

HADES 1.16.0
============

- Adding Strategus to HADES
- CohortExplorer, CohortGenerator, and ResultsModelManager are now in CRAN. Removing reference to Github repos from DESCRIPTION.

HADES 1.15.0
============

- Adding CohortIncidence to HADES

HADES 1.14.0
============

- Adding Keeper to HADES

HADES 1.13.1
============

- CirceR, Eunomia, and FeatureExtraction are now in CRAN. Removing reference to Github repos.

HADES 1.13.0
============

- Adding Achilles to HADES

HADES 1.12.0
============

- Adding BrokenAdaptiveRidge to HADES

HADES 1.11.0
============

Changes

- Adding DataQualityDashboard to HADES

HADES 1.10.0
============

Changes

- Adding ShinyAppBuilder to HADES

HADES 1.9.0
===========

Changes

- Adding Characterization to HADES

HADES 1.8.0
===========

Changes

- Adding ResultModelManager to HADES

HADES 1.7.0
===========

Changes

- Adding OhdsiShinyModules to HADES

HADES 1.6.0
===========

Changes

- Adding PheValuator to HADES

HADES 1.5.0
===========

Changes

- Adding CohortExplorer to HADES

HADES 1.4.0
===========

Changes

- Adding PhenotypeLibrary to HADES

HADES 1.3.0
===========

Changes

- Adding EnsemblePatientLevelPrediction to HADES

HADES 1.2.0
===========

Changes

- Adding Capr to HADES

HADES 1.1.0
===========

Changes

- Adding CohortGenerator to HADES

HADES 1.0.1
===========

Changes

- Moving Eunomia from CRAN to GitHub


Hades 1.0.0
===========

Initial release