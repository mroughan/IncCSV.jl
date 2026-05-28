# Contributing to IncCSV.jl

Thanks for helping improve IncCSV.jl. The project is intentionally small: it is
a lightweight layer over CSV.jl for CSV files with shallow, human-readable
metadata.

Before making design or behavioral changes, read
[`ARCHITECTURE.md`](ARCHITECTURE.md). It records the constraints that keep the
format interoperable and easy to implement.

## Development Setup

This package currently supports Julia 1.10 and later. The JET workflow runs on
Julia 1.12 because the configured JET version requires it.

From the repository root:

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Run the test suite with:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Run JET separately with Julia 1.12 or later:

```sh
julia -e '
using Pkg
Pkg.activate(; temp=true)
Pkg.develop(PackageSpec(path=pwd()))
Pkg.add(PackageSpec(name="JET", version="0.11"))
using IncCSV, JET
JET.test_package(IncCSV; target_modules=(IncCSV,))
'
```

Build the documentation with:

```sh
julia --project=docs docs/make.jl
```

## Contribution Guidelines

- Keep IncCSV a small layer over CSV.jl.
- Preserve compatibility with ordinary CSV files that have no INC metadata
  block.
- Keep metadata one level deep and scalar values limited to `Int` and `String`.
- Treat schema type descriptors as informational unless a broader redesign is
  made explicitly.
- Keep `[structure]` limited to the documented allowlist: `delim`, `delimiter`,
  `quotechar`, `escapechar`, `comment`, `header`, and `footerskip`.
- Preserve permissive defaults unless a schema opts into stricter validation.
- Avoid broad dependencies, deep nesting, or a general configuration language.

When adding file-format behavior, include:

- a checked-in example file, usually under `artifacts/examples` or
  `artifacts/invalid_examples`;
- tests that read the example;
- README and Documenter updates for user-visible behavior;
- an entry in `CHANGELOG.md`.

## Tests and Examples

Positive examples live in `artifacts/examples`. Invalid examples live in
`artifacts/invalid_examples` and should demonstrate one rejected behavior each.
Tests should prefer these checked-in fixtures when they describe format behavior
that other implementations may need to match.

## Documentation

User-facing behavior should be documented in both the README and the relevant
Documenter page under `docs/src`. API details belong in docstrings and
`docs/src/api.md`.

## Pull Requests

Please keep pull requests focused. Small format or validation changes are easier
to review when they include the fixture, test, and documentation updates in the
same change.
