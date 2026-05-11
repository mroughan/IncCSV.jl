---
# Highly restrictive schema for a small assay batch.
# Every data file must carry the same core provenance, assay, and column metadata.
[schema]
allow_extra = false # No metadata outside MUST/MUST_NOT/OPTIONAL is accepted.

[MUST]
title = String
source = String
assay = ControlledString: glucose|lactate|sodium
version = Int
columns = section
columns.sample_id = IdentifierString
columns.value = FloatString
units = section
units.value = UnitString

[MUST_NOT]
operator = PersonName

[description]
title = Dataset title shown in reports
source = Lab or system that produced the file
assay = Controlled assay name encoded as a string
version = Integer schema version
columns = Required per-column metadata section
columns.sample_id = Stable sample identifier column
columns.value = Measured result column
units = Required units metadata section
units.value = Unit for the measured result
operator = Operator names must not be stored in this released assay batch
---
