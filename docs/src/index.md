# IncCSV.jl

IncCSV is a small layer over CSV.jl for CSV files with included metadata.

INC files are assumed to be UTF-8 encoded text.

An INC file starts with a metadata block delimited by `---` lines, followed by
ordinary CSV data:

```text
---
title = Example data
version = 1
[columns]
temperature = Celsius
---
time,temperature
0,21
1,22
```

Metadata is deliberately limited:

- top-level `key = value` pairs
- optional nonempty one-level `[sections]`
- unquoted signed integers are read as `Int`
- quoted values and all other values are read as `String`

The default delimiter between metadata and data is `---`. Readers accept any
sequence of three or more Unicode Punctuation, dash (`Pd`) characters as a
delimiter.

See [Metadata Grammar](@ref) for the extended BNF.
See [Structure Options](@ref) for details on `[structure]` parser hints.
See [Mini Schema](@ref) for lightweight metadata validation using RFC
2119-style `[MUST]`, `[MUST_NOT]`, and `[OPTIONAL]` sections.

Unicode text can appear in metadata and CSV content:

```text
---
title = Café temperatures
city = München
[columns]
temperature = °C
---
name,temperature
Anaïs,21
李,22
```

The CSV component is still parsed and written by CSV.jl, and CSV.jl keyword
options can be passed through `readinc` and `writeinc`.

Files can also include a `[structure]` metadata section with lightweight CSV.jl
reader options. For example, a semicolon-delimited CSV component can declare:

```text
[structure]
delim = ";"
```

The alias `delimiter = ;` is also accepted for interoperability with other INC
implementations.

The supported `[structure]` keys are `delim`, `delimiter`, `quotechar`,
`escapechar`, `comment`, `header`, and `footerskip`. Julia-specific CSV.jl
options outside this allowlist can still be passed directly as `readinc`
keyword arguments.

See [Structure Options](@ref) for examples.

Explicit keyword arguments passed to `readinc` take precedence over `[structure]`
metadata and are applied to the CSV component after the metadata block.

Checked-in examples include semicolon, tab, and pipe delimiters in
`artifacts/examples`.

A compact tutorial script lives at `artifacts/examples/tutorial.jl`. From the
package root, run:

```sh
julia --project=. artifacts/examples/tutorial.jl
```

```julia
using IncCSV

file = readinc("example.inc")
metadata(file)["title"]
table(file)
summarise(file)

schema = readschema("artifacts/examples/default_schema.inc")
validateschema(file, schema)
printsummary(file)
```

```julia
using DataFrames

file = readinc("example.inc", DataFrame; comment="#")
table(file)
```

Small checked-in example files live in `artifacts/examples`.
