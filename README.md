# IncCSV.jl

INC is

    INi-Csv

or

    Ini - aNd - Csv

or

    INCluded metadata

or

    Intrinsic aNd Connate metadata

IncCSV is a small layer over CSV.jl for CSV files with included metadata.

INC files are assumed to be UTF-8 encoded text.

The package's design commitments are recorded in
[`ARCHITECTURE.md`](ARCHITECTURE.md).

An INC file is just:

```text
---
title = Example data
[columns]
temperature = Celsius
---
time,temperature
0,21.4
1,21.8
```

The metadata block is deliberately small: `key = value` pairs, plus optional
one-level sections. Unquoted signed integers are read as `Int`; quoted values
and all other values are read as strings. The CSV data is still read and
written by CSV.jl.

The default delimiter between metadata and data is `---`. Readers accept any
sequence of three or more Unicode Punctuation, dash (`Pd`) characters as a
delimiter.

The optional `[structure]` section can provide lightweight CSV.jl reader
options for the CSV component. For example, `delim = ";"` declares a
semicolon-delimited table. Explicit keyword arguments passed to `readinc`
override `[structure]` values.

Examples of semicolon-, tab-, and pipe-delimited INC files live in
`artifacts/examples`.

A permissive default schema of common metadata terms is provided at
`artifacts/examples/default_schema.inc`.

The extended BNF for the metadata block is in `docs/src/metadata.md`.
The lightweight metadata schema format is in `docs/src/schema.md`.

Unicode text works in metadata and CSV content:

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

```julia
using IncCSV

file = readinc("example.inc")
metadata(file)["title"]
table(file)
```

Plain CSV files can also be read with `readinc`; they simply return empty
metadata.

```julia
rows = [(time=0, temperature=21.4), (time=1, temperature=21.8)]

writeinc(
    "example.inc",
    rows;
    metadata=Dict(
        "title" => "Example data",
        "columns" => Dict("temperature" => "Celsius"),
    ),
)
```

Small checked-in example files live in `artifacts/examples`.

## Disclosure

This package was developed with assistance from OpenAI Codex, an AI coding
assistant based on GPT-5. Code design decisions were human mediated, and the
resulting code was manually reviewed.
