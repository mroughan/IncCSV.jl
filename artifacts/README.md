# IncCSV Artifacts

This directory contains small example files used by the package tests and
documentation.

These are checked into the repository because they are tiny, human-readable
format examples rather than large binary artifacts.

The `examples` directory includes `tutorial.jl`, a small runnable walkthrough
that reads INC files, uses `[structure]` parser hints, validates metadata with a
schema, and writes a roundtrip example.

The `schema_examples` directory contains three small folders showing restrictive,
informational, and balanced metadata schemas. Each folder includes a schema,
three INC files, and Julia code that validates the files and reports
schema-informed metadata.

The `invalid_examples` directory contains intentionally invalid INC files used
by the tests to demonstrate rejected parser, structure, and schema behavior.

`examples/default_schema.inc` is a permissive default schema documenting common
metadata terms for discovery, preservation, technical details, rights,
structure, parameters, statistical qualities, and process information.
