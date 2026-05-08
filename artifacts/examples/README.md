# Example Files

This directory contains small, checked-in files that exercise IncCSV format
features. They are used by the test suite and can also be read directly while
learning the package.

## Tutorial

`tutorial.jl` is a compact runnable walkthrough. It reads a normal INC file into
a `DataFrame`, uses `[structure]` metadata to read tab-delimited data, validates
metadata against the default schema, and writes a small INC file back out.

For a first interactive read from the package root:

```sh
julia --project=. artifacts/examples/tutorial.jl
```

From the package root:

```julia
using DataFrames
using IncCSV

file = readinc("artifacts/examples/demo.inc", DataFrame)
metadata(file)
table(file)
```

## Basic Files

- `demo.inc`: standard INC file with metadata, integer metadata inference, and a CSV component.
- `plain.csv`: ordinary CSV file; `readinc` reads it with empty metadata.
- `dataframe.inc`: small INC file used for DataFrame sink/source examples.
- `commented.inc`: metadata comments plus CSV comments parsed with `comment="#"`.
- `unicode.inc`: UTF-8 metadata and CSV content.
- `unicode_delimiter.inc`: metadata delimiters using Unicode dash punctuation.

## Structure Examples

These files use `[structure]` metadata to provide CSV.jl reader options:

- `structured_semicolon.inc`: semicolon-delimited CSV component with `delim = ";"`.
- `structured_tsv.inc`: tab-delimited CSV component with `delim = tab`.
- `structured_pipe.inc`: pipe-delimited CSV component with `delim = "|"`.

Example:

```julia
file = readinc("artifacts/examples/structured_tsv.inc", DataFrame)
table(file)
```

Explicit keyword arguments passed to `readinc` override `[structure]` values.

## Schema Examples

- `metadata_schema.inc`: compact schema used by unit tests.
- `missing_required.inc`: example INC file missing a required schema field.
- `default_schema.inc`: permissive default schema documenting common metadata terms.

Example:

```julia
schema = readschema("artifacts/examples/default_schema.inc")
file = readinc("artifacts/examples/demo.inc")
report = validateschema(file, schema)
```

`default_schema.inc` has no `MUST` fields and allows extra metadata. It is meant
as a starting point for documentation and light reporting, not as a strict
validation contract.
