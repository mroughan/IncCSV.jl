# IncCSV Architecture

This document records the primary design decisions that should be preserved as
IncCSV evolves.

## Purpose

IncCSV is a lightweight layer over CSV.jl for tabular data files that include
small, human-readable metadata in the same file.

The package should make the common case easy. It is not intended to replace
CSV.jl, TOML, YAML, JSON, XML, Frictionless Data, or a full metadata catalogue.

## Core Principles

- Keep the format readable by people using ordinary text editors.
- Reuse CSV.jl for CSV parsing and writing.
- Keep metadata parsing small, predictable, and easy to inspect.
- Prefer explicit (restricted) behavior over clever inference.
- Preserve ordinary CSV workflows wherever possible, including backward compatibility with simple CSV files without metadata.
- Avoid expanding the metadata language into a general configuration language.

## File Model

An INC file is UTF-8 encoded text.

The file may start with a metadata block delimited by lines containing three or
more Unicode `Punctuation, dash` (`Pd`) characters. The default delimiter
written by IncCSV is three ASCII hyphen-minus characters:

```text
---
```

The metadata block is followed by a CSV-like tabular component. The tabular
component is parsed and written by CSV.jl.

Plain CSV files without an INC metadata block remain valid inputs to `readinc`;
they return empty metadata.

## Metadata

Metadata is intentionally limited:

- Top-level `key = value` pairs.
- Optional one-level sections.
- Sections must contain at least one property.
- No nested sections beyond one level.
- No arrays, tables, expressions, imports, includes, interpolation, or schema
  enforcement inside the base metadata parser.

Metadata values are limited to:

- `Int`
- `String`

Unquoted signed integers are parsed as `Int`. Quoted values and all other
values are parsed as `String`.

This narrow type system is deliberate. Richer interpretation belongs in
documentation, schema descriptors, or downstream code.

## Reserved Sections

Most metadata sections are user-defined. Some section names have package-level
meaning.

### `[structure]`

The `[structure]` section may provide lightweight CSV.jl reader options for the
CSV component.

Supported structure keys should remain a small allowlist. The current intent is
to support practical parsing hints such as delimiters, comments, and simple
CSV.jl reader options.

`delimiter` is accepted as a read-only alias for `delim` for interoperability
with other INC implementations; internally both map to CSV.jl's `delim`
keyword.

Explicit keyword arguments passed to `readinc` always override `[structure]`
metadata. Reader options are applied to the CSV component after the metadata
block, not to the whole physical INC file.

`writeinc` writes the CSV component using explicit Julia arguments; it should
not infer or invent `[structure]` metadata unless that behavior is intentionally
designed later.

## Schemas

IncCSV schemas are lightweight metadata schemas stored using the same INC
metadata syntax.

Schemas may define:

- `[MUST]`: metadata paths that must appear.
- `[MUST_NOT]`: metadata paths that must not appear.
- `[OPTIONAL]`: metadata paths that may appear.
- `[description]`: human-readable descriptions.
- `[schema]`: schema-level settings such as `allow_extra`.

The schema requirement words follow IETF RFC 2119
(`https://www.rfc-editor.org/rfc/rfc2119`). IncCSV uses the spelling `MUST_NOT`
rather than `MUST NOT` so the requirement can be represented as a single INC
section name.

Schemas validate presence and report extras. They do not enforce rich type
descriptors beyond the base metadata parser's `Int` and `String` values.
Schema paths are either top-level names or one-level `section.key` paths. Deeper
paths are outside the INC metadata model and should be rejected.

Type descriptor strings in schemas are informational. They may be used by
humans or downstream tools, but IncCSV should not silently grow a rich type
system around them.

By default, schemas allow metadata fields beyond those listed in `[MUST]`,
`[MUST_NOT]`, and `[OPTIONAL]`. A schema can opt into closed validation with:

```text
[schema]
allow_extra = false
```

## API Shape

The public API should stay small and direct:

- `readinc`
- `writeinc`
- `metadata`
- `table`
- `readschema`
- `validateschema`
- `summarise`
- `printsummary`
- simple result containers such as `IncFile`, `IncSchema`, and
  `IncSummary`, and `SchemaValidation`

Avoid adding broad abstractions unless they simplify real user workflows.

## Compatibility Expectations

Existing INC files should remain readable unless a change fixes a clear bug or
security/safety issue.

When adding features:

- Prefer opt-in behavior.
- Preserve default permissive behavior.
- Let explicit Julia keyword arguments override metadata-derived defaults.
- Add checked-in example files and tests for new file-format behavior.
- Update Documenter docs and README when behavior changes.

## Non-Goals

IncCSV should not become:

- a general-purpose metadata standard,
- a full schema validation language,
- a nested document format,
- a replacement for CSV.jl,
- a metadata catalogue or search system,
- a complex serialization format.

The project succeeds when it covers common metadata needs with very little
machinery.
