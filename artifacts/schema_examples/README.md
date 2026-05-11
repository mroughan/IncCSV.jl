# Schema Example Suites

This directory contains three small folders that show different ways to use
IncCSV's lightweight metadata schemas.

Each suite contains:

- `schema.inc`: schema written as an INC metadata block.
- three `.inc` data files matching the schema's intent.
- `run.jl`: Julia code that reads the schema and files, validates them, and
  returns a schema-informed metadata report.

Run a suite from the package root with:

```bash
julia --project=. artifacts/schema_examples/balanced/run.jl
```

Or include it from Julia:

```julia
reports = include("artifacts/schema_examples/balanced/run.jl")
```

Each report includes:

- `file`: file name.
- `valid`: whether the metadata passes schema validation.
- `missing`: required fields not present.
- `extra`: metadata paths not described by the schema.
- `forbidden`: `MUST_NOT` metadata paths that were present.
- `rows`: number of table rows.
- `columns`: parsed table column names.
- `metadata_report`: per-field schema context including requirement, type,
  description, presence, and value.

Schemas should use the canonical RFC 2119-style sections `[MUST]`,
`[MUST_NOT]`, and `[OPTIONAL]`. IncCSV also accepts read-only aliases when
reading schemas: `[REQUIRED]` and `[SHALL]` for `[MUST]`, `[SHALL_NOT]` for
`[MUST_NOT]`, and `[MAY]` for `[OPTIONAL]`.

## Suites

### `restrictive`

A highly restrictive lab-assay example.

- The schema uses `[schema] allow_extra = false`.
- Every listed core field must be present.
- Metadata outside `[MUST]`, `[MUST_NOT]`, and `[OPTIONAL]` fails validation.
- The schema uses `[MUST_NOT]` to reject metadata that must not appear.
- Useful when files should follow a fixed contract.

Files:

- `assay_glucose.inc`
- `assay_lactate.inc`
- `assay_sodium.inc`

### `informational`

A permissive field-notes example.

- The schema has only `[OPTIONAL]` fields.
- Extra metadata is expected and allowed.
- Useful when a schema mainly documents common vocabulary.

Files:

- `park_notes.inc`
- `reef_notes.inc`
- `library_notes.inc`

### `balanced`

A simulation-run example between the two extremes.

- A small core is required with `[MUST]`.
- Provenance and run details are optional with `[OPTIONAL]`.
- Extra metadata is allowed and reported.
- Useful when files need enough metadata to be interpretable but should still
  allow project-specific fields.

Files:

- `run_baseline.inc`
- `run_stress.inc`
- `run_recovery.inc`
