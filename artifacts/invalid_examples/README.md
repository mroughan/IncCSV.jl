# Invalid Example Files

This directory contains small INC files that intentionally violate one format
or schema rule each. They are used by the test suite to make sure invalid
inputs fail predictably.

These files are not examples to copy for normal use.

## Files

- `empty_section.inc`: metadata section with no key-value properties.
- `invalid_key.inc`: top-level key containing whitespace.
- `invalid_section_name.inc`: section name containing whitespace.
- `invalid_section_key.inc`: section key containing whitespace.
- `missing_closing_delimiter.inc`: metadata block with no closing delimiter.
- `repeated_key.inc`: repeated top-level metadata key.
- `structure_invalid_comment.inc`: non-string `comment` value in `[structure]`.
- `structure_invalid_char.inc`: single-character `[structure]` value with too many characters.
- `structure_invalid_int.inc`: integer `[structure]` value written as a string.
- `unsupported_structure_key.inc`: unsupported `[structure]` key.
- `schema_duplicate_requirement.inc`: schema field declared in two requirement sections.
- `schema_duplicate_alias_requirement.inc`: schema field repeated through RFC 2119 aliases.
- `schema_deep_path.inc`: schema path deeper than one `section.key` level.

## Quick Check

From the package root, these should all throw `ArgumentError` when read with
the appropriate reader:

```julia
using IncCSV

readinc("artifacts/invalid_examples/empty_section.inc")
readschema("artifacts/invalid_examples/schema_deep_path.inc")
```
