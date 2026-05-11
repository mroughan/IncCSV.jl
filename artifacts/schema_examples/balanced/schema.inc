---
# Balanced schema for simulation runs.
# Files must have enough metadata to be interpretable, but optional fields allow
# extra provenance and reproducibility details when they are available.
[MUST]
title = String
source = String
model = ModelNameString
run_id = String
columns = section
columns.time = IntegerLikeString
columns.value = NumericString

[OPTIONAL]
seed = Int
version = Int
scenario = ControlledString: baseline|stress|recovery
software = PackageVersionString
units = section
units.value = UnitString

[description]
model = Name of the simulation model
run_id = Stable run identifier
seed = Random seed when the run is stochastic
scenario = Scenario label used for grouping
software = Software and version used to generate the run
columns = Required per-column metadata section
columns.time = Time-step column
columns.value = Simulated value column
units = Optional units metadata section
units.value = Unit for the simulated value
---
