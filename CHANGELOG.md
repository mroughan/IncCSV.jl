# Changelog

All notable changes to IncCSV.jl are recorded here.

This project does not currently have a published release history. Until the
first tagged release, changes are collected under `Unreleased`.

## Unreleased

### Added

- Add `CONTRIBUTING.md` with the local development workflow and project
  contribution guidelines.
- Add this changelog.

### Changed

- Require `[structure].comment` metadata to be a single-character string.
- Restore main package compatibility to Julia 1.10 and move JET checks out of
  the default package test target.

### Fixed

- Add an invalid example and test coverage for multi-character
  `[structure].comment` values.

## 0.1.0

- Initial package version declared in `Project.toml`.
