# Changelog

All notable changes to IncCSV.jl are recorded here.

## Unreleased

No unreleased changes.

## 0.1.0 - 2026-05-28

First public release of IncCSV.jl.

### Added

- Add `readinc` and `writeinc` for reading and writing INC files: small
  INI-style metadata blocks followed by CSV data parsed and written by CSV.jl.
- Add accessors for parsed INC files through `metadata` and `table`.
- Add support for ordinary CSV files with no metadata block; these read with
  empty metadata.
- Add metadata parsing for top-level `key = value` pairs and one-level
  sections, with scalar values limited to `Int` and `String`.
- Add support for metadata delimiters made from three or more Unicode dash
  punctuation characters.
- Add `[structure]` reader hints for `delim`, `delimiter`, `quotechar`,
  `escapechar`, `comment`, `header`, and `footerskip`.
- Add lightweight schema support through `readschema` and `validateschema`,
  including `[MUST]`, `[MUST_NOT]`, `[OPTIONAL]`, descriptions, and
  `allow_extra`.
- Add `summarise` and `printsummary` helpers for compact file summaries.
- Add checked-in positive and negative examples under `artifacts/`.
- Add Documenter documentation, README examples, CI, Aqua, JET, coverage,
  CompatHelper, and TagBot workflows.
- Add `ARCHITECTURE.md`, `CONTRIBUTING.md`, and this changelog.

### Changed

- Require `[structure].comment` metadata to be a single-character string.
- Support Julia 1.10 and later for the main package, with JET checks run
  separately on Julia 1.12 or later.

### Fixed

- Add an invalid example and test coverage for multi-character
  `[structure].comment` values.
