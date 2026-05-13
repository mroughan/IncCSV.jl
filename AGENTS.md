# Agent Instructions

Before making design or behavioral changes to this package, read
[`ARCHITECTURE.md`](ARCHITECTURE.md).

Preserve the core direction of the project:

- IncCSV is a lightweight layer over CSV.jl.
- Metadata remains small, human-readable, and one-level deep.
- Metadata scalar values remain limited to `Int` and `String`.
- Rich schema type descriptors are informational unless explicitly redesigned.
- `[structure]` provides only the documented allowlist of CSV parsing hints
  (`delim`, `delimiter`, `quotechar`, `escapechar`, `comment`, `header`, and
  `footerskip`); explicit Julia kwargs win.
- Default behavior should remain permissive unless a schema opts into stricter
  validation.

When adding file-format behavior, also add:

- a checked-in example file,
- tests that read the example,
- relevant updates to README and Documenter docs.

Do not introduce broad dependencies, deep nesting, or a general configuration
language without first updating `ARCHITECTURE.md` and making the design tradeoff
explicit.
