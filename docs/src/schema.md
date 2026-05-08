# Mini Schema

IncCSV supports a lightweight schema for metadata. The schema is itself stored
as an INC metadata block, so it uses the same syntax, comments, UTF-8 encoding,
and delimiter rules as ordinary metadata.

The schema sections are:

- `[schema]`: optional schema-level settings.
- `[MUST]`: fields that must appear in each INC file.
- `[MAYBE]`: fields that may appear.
- `[description]`: optional human-readable descriptions for fields.

Field names in `[MUST]` and `[MAYBE]` are metadata paths. Top-level metadata
uses plain names such as `title`; keys inside metadata sections use dotted
paths such as `columns.score`. A section itself can be described by its section
name, such as `columns`.

```text
---
[schema]
allow_extra = true

[MUST]
title = String
source = String
columns = section
columns.score = String

[MAYBE]
version = Int
created = Date: yyyy-mm-dd

[description]
title = Human-readable dataset title
created = Date encoded as a string
---
```

By default, `allow_extra = true`: additional metadata fields are allowed and
returned in `report.extra`. Set `allow_extra = false` for a closed schema where
only the fields listed in `[MUST]` and `[MAYBE]` are accepted.

The values in `[MUST]` and `[MAYBE]` are type descriptor strings. They may be
more specific than IncCSV's built-in metadata value types. IncCSV records these
descriptors but does not parse string values according to them.

```julia
schema = readschema("metadata_schema.inc")
file = readinc("example.inc")
report = validateschema(file, schema)

report.valid
report.missing
report.extra
```

Additional metadata fields are allowed. They are returned in `report.extra`
because other tools may not understand them.

Worked example suites live in `artifacts/schema_examples`:

- `restrictive`: a lab-assay folder where every file must carry the same core metadata.
- `informational`: a field-notes folder where the schema mainly documents common terms.
- `balanced`: a simulation folder with a required core and optional provenance fields.

Each directory contains a `schema.inc`, three matching INC files, and a `run.jl`
script that reads the files, validates them, and returns a schema-informed
metadata report.

A permissive default schema of common discovery, preservation, technical,
rights, structure, parameter, statistical, and process terms is available at
`artifacts/examples/default_schema.inc`. It contains no `MUST` fields and is
intended as a starting point for documentation and light reporting.

The package tutorial at `artifacts/examples/tutorial.jl` shows this default
schema in use alongside ordinary reading and writing.
