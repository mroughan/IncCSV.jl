# Metadata Grammar

This grammar describes the metadata block at the start of an INC file. The CSV
component after the closing delimiter is parsed by CSV.jl and is outside this
grammar.

INC files are assumed to be UTF-8 encoded text. Characters in this grammar are
Unicode scalar values decoded from UTF-8.

```ebnf
inc-file        = [ metadata-block ], csv-component ;

metadata-block  = delimiter, newline,
                  { metadata-line },
                  delimiter, newline ;

metadata-line   = blank-line
                | comment-line
                | property-line
                | section-line ;

blank-line      = whitespace, newline ;
comment-line    = whitespace, comment, newline ;

section-line    = whitespace, "[", name, "]", whitespace,
                  [ comment ], newline ;

property-line   = whitespace, name, whitespace, "=", whitespace,
                  value, whitespace, [ comment ], newline ;

value           = integer | quoted-string | bare-string ;

integer         = [ "+" | "-" ], digit, { digit } ;

quoted-string   = '"', { quoted-character | escape-sequence }, '"' ;
escape-sequence = "\", ( '"' | "\" ) ;
quoted-character = ? any character except '"' or "\" ? ;

bare-string     = { bare-character } ;
bare-character  = ? any character except newline ? ;

comment         = ( "#" | ";" ), { ? any character except newline ? } ;

delimiter       = whitespace, dash, dash, dash, { dash }, whitespace,
                  [ comment ] ;
dash            = ? any Unicode character in category Punctuation, dash (Pd) ? ;

name            = name-character, { name-character } ;
name-character  = ? any character except whitespace, "=", "[", "]", "#", or ";" ? ;

whitespace      = { " " | "\t" } ;
digit           = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;
newline         = "\n" | "\r\n" ;
```

Names are used for both top-level keys and one-level section names. Section
entries use the same `property-line` form as top-level metadata. Keys and
section names may not contain whitespace or any of `=[]#;`; section names must
not be empty, and sections must contain at least one property.

```text
---
title = Example data
version = 1
offset = -3

[columns]
temperature = Celsius
---
```

Unquoted values matching `integer` are read as `Int`. Quoted values and all
other values are read as `String`. Quoting an integer-like value forces it to
remain a string:

```text
version = 1
sample_id = "001"
```

Comments begin with `#` or `;` outside quoted strings. They are stripped from
metadata before parsing values when they appear on a comment line, after a
section header, or after a nonempty value separated by whitespace. A bare
comment marker can also be a value, so `delim = ;` reads as the string `";"`
and `comment = #` reads as the string `"#"`. Empty and whitespace-only values
read as the empty string.

`[structure]` is a conventional metadata section used by IncCSV to pass a small
set of CSV.jl reader options to the CSV component. Values still follow the same
metadata grammar:

```text
[structure]
delim = ";"
delimiter = ;
comment = "#"
```

For tab-delimited files, use `delim = tab`. For pipe-delimited files, use
`delim = "|"`.

Supported `[structure]` keys are deliberately limited to a small allowlist:

| Key | Type | Meaning |
| --- | --- | --- |
| `delim` | character | Delimiter between CSV fields. |
| `delimiter` | character | Alias for `delim`; if both appear, `delimiter` wins. |
| `quotechar` | character | Quote character used by the CSV component. |
| `escapechar` | character | Escape character used by the CSV component. |
| `comment` | string | Comment marker used by the CSV component. |
| `header` | integer | CSV component line containing column names. |
| `footerskip` | integer | Number of trailing CSV component rows to ignore. |

`delimiter` is a read-only alias for `delim`; if both appear, `delimiter` takes
precedence. Single-character options accept a one-character string, `tab`,
`space`, `\t`, or an integer Unicode code point such as `44` for comma.

Integer options accept unquoted integer values. Line-oriented options are
relative to the CSV component after the metadata block, not to the physical
first line of the INC file.

This allowlist is intentionally smaller than CSV.jl's full keyword set. It is
based on CSV.jl names where practical, with an eye toward behavior that other
INC implementations can support consistently. Use explicit
`readinc(...; kwargs...)` calls for Julia-specific CSV.jl options such as
`skipto`, `limit`, `missingstring`, `dateformat`, `normalizenames`,
`ignoreemptyrows`, `ignorerepeated`, `decimal`, or `groupmark`.

Explicit keyword arguments passed to `readinc` override `[structure]` values.
These options are applied to the CSV component after the metadata block.

See [Structure Options](@ref) for more detail and examples.

The default delimiter is three ASCII hyphen-minus characters:

```text
---
```

Readers also accept any sequence of three or more Unicode characters in the
Punctuation, dash (`Pd`) category, including mixed dash characters:

```text
———
‐–—
```

The dash characters in a delimiter must be consecutive. A line such as
`- - -` is not a delimiter.

## Writing and Diagnostics

`writeinc` accepts metadata values that are only `Int` or `String`, with
one-level sections whose values are also only `Int` or `String`. It rejects
`Bool`, `Float64`, `Date`, `nothing`, `missing`, arrays, nested sections,
invalid keys, empty sections, and strings containing literal newlines. String
values containing `"`, `\`, leading or trailing whitespace, comment markers,
brackets, `=`, or integer-like text are quoted and escaped so they round-trip.

Parser and writer errors are reported as `ArgumentError`s. Common diagnostics
include empty or invalid metadata sections, invalid metadata keys, repeated
sections or keys, invalid metadata lines without `=`, missing closing
delimiters, unsupported `[structure]` keywords, and metadata values outside the
`Int`/`String` type set.
