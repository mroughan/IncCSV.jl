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
bare-character  = ? any character except newline, "#", or ";" ? ;

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
entries use the same `property-line` form as top-level metadata:

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
metadata before parsing values.

`[structure]` is a conventional metadata section used by IncCSV to pass a small
set of CSV.jl reader options to the CSV component. Values still follow the same
metadata grammar, so comment characters such as `;` must be quoted when used as
values:

```text
[structure]
delim = ";"
comment = "#"
ignoreemptyrows = true
```

For tab-delimited files, use `delim = tab`. For pipe-delimited files, use
`delim = "|"`.

Supported `[structure]` keys are:

- single-character options: `delim`, `quotechar`, `escapechar`, `decimal`, `groupmark`
- string options: `comment`, `missingstring`, `dateformat`
- boolean options: `ignoreemptyrows`, `ignorerepeated`, `normalizenames`
- integer options: `header`, `skipto`, `footerskip`, `limit`

Explicit keyword arguments passed to `readinc` override `[structure]` values.

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
