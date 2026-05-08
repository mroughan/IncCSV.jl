# IncCSV.jl

[![Stable](https://img.shields.io/badge/docs-dev-blue.svg)](https://mroughan.github.io/IncCSV.jl/dev)

IncCSV is a small layer over CSV.jl to include metadata into  CSV files, resulting in what we call INC files. It is simple, lightweight, pragmatic and intended to be useful to everyday users who currently use CSV files, and should include some metadata, but shy away from more complicated ways to do so. 

INC is **IN**i+**C**sv or **I**ni - a**N**d - **C**sv
 or **INC**luded metadata
 or **I**ntrinsic a**N**d **C**onnate metadata.

INC is motivated by the observations that 
+ CSV (or one of the related formats) is incredibly successful as a data format because we often think in terms of tabular data, and 
+ many tabular datasets require only a small, shallow metadata structure.

INC is intended to complement rather than replace CSVW and Frictionless Data as well as powerful generic systems like systems like JSON and XML. 

An INC file is just a metadata part (in INI file format) followed by a data part (in CSV format). For example:

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

The package is intended to provide a very lightweight method to handle a very common case: simple metadata that describes tabular data. 

The package's design commitments are recorded in
[`ARCHITECTURE.md`](ARCHITECTURE.md) and full documentation 
can be found here [![Stable](https://img.shields.io/badge/docs-dev-blue.svg)](https://mroughan.github.io/IncCSV.jl/dev).



It is worth repeating the core principles, *i.e.,* safety, portability and simplicty, so: 

- Keep the format readable by people using ordinary text editors.
- Reuse CSV.jl for CSV parsing and writing.
- Keep metadata parsing small, predictable, and easy to inspect.
- Prefer explicit (restricted) behavior over clever inference.
- Preserve ordinary CSV workflows wherever possible, including backward compatibility with simple CSV files without metadata.
- Avoid expanding the metadata language into a general configuration language.

and the **non-goals** are:  

- a general-purpose metadata standard,
- a full schema validation language,
- a nested document format,
- a replacement for CSV.jl,
- a metadata catalogue or search system,
- a complex serialization format.

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

A short runnable tutorial is provided at `artifacts/examples/tutorial.jl`.
From the package root, run:

```sh
julia --project=. artifacts/examples/tutorial.jl
```

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
summarise(file)
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

Small checked-in example files live in `artifacts/examples`; start with
`artifacts/examples/tutorial.jl` for a compact read, validate, and write
walkthrough.

## Disclosure

This package was developed with assistance from OpenAI Codex, an AI coding
assistant based on GPT-5. Code design decisions were human mediated, and the
resulting code was manually reviewed.

## Related approaches

A number of existing formats incorporate metadata directly within tabular data files using header structures preceding the data. The CSVY format combines a YAML front matter block with a CSV body, allowing structured metadata to be stored within a single file. Similarly, the Enhanced CSV (ECSV) format developed within the Astropy ecosystem stores column metadata, datatypes, and units in a YAML header preceding tabular data rows. These formats demonstrate the practicality and usefulness of combining lightweight structured metadata with human-readable tabular text.

Earlier precedents exist in domain-specific table formats such as the IPAC Table Format and FITS tables used in astronomy. These formats embed metadata describing column structure and interpretation within the same file as the data, reflecting a long-standing recognition that self-describing datasets improve portability and reuse.

The present proposal differs from these approaches primarily in its deliberate restriction of metadata structure. Rather than adopting YAML or similar general-purpose serialisation languages, it uses a constrained INI-style metadata representation intended to minimise syntactic complexity while preserving human readability and ease of implementation.

An alternative strategy is to store metadata separately from tabular data files. The Frictionless Data specifications define Table Schema and Data Package formats for describing tabular datasets using JSON metadata. These specifications provide lightweight schema validation and packaging mechanisms and have seen adoption in data publishing workflows. However, they are primarily designed to describe collections of files rather than individual self-contained datasets.

Similarly, the Data Documentation Initiative (DDI) provides a comprehensive XML-based framework for describing social-science datasets. While highly expressive and widely used in archival contexts, DDI addresses a broader problem than the one considered here and introduces substantially greater structural complexity.

Although sidecar metadata formats provide advantages for managing collections of related datasets, they introduce the risk that metadata may become separated from the data files they describe. In contexts involving long-term storage, file transfer, or ad hoc data sharing, embedding essential metadata within the data file itself improves robustness and portability.

These approaches try to solve the general problem of metadata, and a consequently feature rich, but that results in complexity. IncCSV aims to provide an interface that is only marginally more complex than the CSV package itself to encourage more universal incorporation of metadata. 

The guiding principle of the approach is that most tabular datasets require only a small, shallow metadata structure and that simplicity promotes adoption. By combining a restricted INI-style metadata header with a conventional delimiter-separated data section, the format aims to provide a practical balance between expressiveness, portability, and ease of use for the common case of standalone tabular datasets.
