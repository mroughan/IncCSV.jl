# Mini Schema

IncCSV supports a lightweight schema for metadata. The schema is itself stored
as an INC metadata block, so it uses the same syntax, comments, UTF-8 encoding,
and delimiter rules as ordinary metadata.

The schema sections are:

- `[schema]`: optional schema-level settings.
- `[MUST]`: fields that must appear in each INC file.
- `[MUST_NOT]`: fields that must not appear in each INC file.
- `[OPTIONAL]`: fields that may appear.
- `[description]`: optional human-readable descriptions for fields.

The schema keywords follow the requirement language from
[IETF RFC 2119](https://www.rfc-editor.org/rfc/rfc2119): `MUST`, `MUST NOT`,
and `OPTIONAL`. IncCSV uses the section name `[MUST_NOT]`, with an underscore,
so that the keyword fits the INC section-name grammar.

For reading, IncCSV also accepts RFC 2119 aliases: `[REQUIRED]` and `[SHALL]`
are aliases for `[MUST]`, `[SHALL_NOT]` is an alias for `[MUST_NOT]`, and
`[MAY]` is an alias for `[OPTIONAL]`. These aliases are read-only conveniences;
the canonical section names for new schemas are `[MUST]`, `[MUST_NOT]`, and
`[OPTIONAL]`.

Field names in `[MUST]`, `[MUST_NOT]`, `[OPTIONAL]`, and their aliases are
metadata paths.
Top-level metadata uses plain names such as `title`; keys inside metadata
sections use dotted paths such as `columns.score`. A section itself can be
described by its section name, such as `columns`. Paths are limited to either
a top-level name or one-level `section.name` path; deeper paths such as
`a.b.c` are rejected because INC metadata has only one level of sections.

```text
---
[schema]
allow_extra = true

[MUST]
title = String
source = String
columns = section
columns.score = String

[OPTIONAL]
version = Int
created = Date: yyyy-mm-dd

[MUST_NOT]
password = String

[description]
title = Human-readable dataset title
created = Date encoded as a string
password = Secrets must not be stored in INC metadata
---
```

By default, `allow_extra = true`: additional metadata fields are allowed and
returned in `report.extra`. Set `allow_extra = false` for a closed schema where
only the fields listed in `[MUST]`, `[MUST_NOT]`, and `[OPTIONAL]` are accepted.
Fields listed in `[MUST_NOT]` always make validation fail if they are present;
they are reported in `report.forbidden`.

The same path may appear in only one requirement section. For example, a field
cannot be both `[MUST]` and `[OPTIONAL]`. When a schema declares
`columns.score`, the parent section `columns` is treated as known for extra
field reporting even if the schema does not explicitly include
`columns = section`.

The values in `[MUST]`, `[MUST_NOT]`, `[OPTIONAL]`, and their aliases are type
descriptor strings. They may be more specific than IncCSV's built-in metadata
value types. IncCSV records these descriptors but does not parse string values
according to them.

```julia
schema = readschema("metadata_schema.inc")
file = readinc("example.inc")
report = validateschema(file, schema)

report.valid
report.missing
report.extra
report.forbidden
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
