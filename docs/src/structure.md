# Structure Options

The optional `[structure]` section stores a small allowlist of CSV reader
options inside an INC file. These options describe how to parse the CSV
component after the metadata block.

`[structure]` is intentionally limited. It is not a place to store every CSV.jl
keyword argument. Options outside the allowlist can still be passed directly to
[`readinc`](@ref) as Julia keyword arguments.

Explicit keyword arguments passed to `readinc` always override values from
`[structure]`.

## Allowed Keys

| Key | Type | Meaning |
| --- | --- | --- |
| `delim` | character | Delimiter between CSV fields. |
| `delimiter` | character | Alias for `delim`; if both appear, `delimiter` wins. |
| `quotechar` | character | Quote character used by the CSV component. |
| `escapechar` | character | Escape character used by the CSV component. |
| `comment` | string | Comment marker used by the CSV component. |
| `header` | integer | CSV component line containing column names. |
| `footerskip` | integer | Number of trailing CSV component rows to ignore. |

The key names are based primarily on CSV.jl keyword arguments. The alias
`delimiter` is accepted for interoperability with other INC implementations.

## Value Rules

Values in `[structure]` use the same metadata value rules as the rest of the INC
metadata block:

- unquoted signed integers are read as `Int`;
- quoted values are read as strings;
- unquoted non-integer values are read as strings.

Character options accept:

- a one-character string, such as `delim = "|"` or `quotechar = "'"`;
- `tab` for the tab character;
- `space` for a space character;
- `\t` for the tab character;
- an integer Unicode code point, such as `delim = 44` for comma.

Integer options such as `header` and `footerskip` must be unquoted integers.
For example, use `header = 2`, not `header = "2"`.

Line-oriented options are relative to the CSV component after the closing INC
metadata delimiter. They are not counted from the physical first line of the INC
file.

## Examples

### Semicolon-Delimited Data

```text
---
title = Semicolon data
[structure]
delim = ";"
---
name;score
Ada;21
Babbage;12
```

```julia
using DataFrames
using IncCSV

file = readinc("semicolon.inc", DataFrame)
table(file)
```

The alias `delimiter` can also be used:

```text
[structure]
delimiter = ;
```

If both `delim` and `delimiter` appear, `delimiter` takes precedence.

### Tab-Delimited Data

```text
---
title = Tab data
[structure]
delim = tab
---
name	score
Ada	21
Babbage	12
```

```julia
file = readinc("tab.inc", DataFrame)
```

### Commented CSV Rows

`comment` applies only to the CSV component. Metadata comments are always `#`
or `;`.

```text
---
title = Commented data
[structure]
comment = "#"
---
name,score
# ignored row
Ada,21
```

```julia
file = readinc("commented.inc", DataFrame)
```

### Non-Default Quote Character

```text
---
title = Quote character data
[structure]
quotechar = "'"
---
name,note
Ada,'hello, world'
```

```julia
file = readinc("quotechar.inc", DataFrame)
table(file).note
```

### Non-Default Escape Character

```text
---
title = Escape character data
[structure]
escapechar = |
---
name,note
Ada,"say |"hi|""
```

```julia
file = readinc("escapechar.inc", DataFrame)
table(file).note
```

### Header On A Later CSV Line

`header` is counted from the first line of the CSV component, after the closing
metadata delimiter.

```text
---
title = Later header
[structure]
header = 2
---
discard,discard
name,score
Ada,21
```

```julia
file = readinc("later_header.inc", DataFrame)
```

### Skipping Footer Rows

```text
---
title = Footer data
[structure]
footerskip = 1
---
name,score
Ada,21
Babbage,12
TOTAL,33
```

```julia
file = readinc("footer.inc", DataFrame)
```

## Explicit Keyword Arguments

Caller-supplied keyword arguments override `[structure]` values:

```julia
file = readinc("data.inc", DataFrame; delim='|')
```

Use explicit keyword arguments for CSV.jl options outside the `[structure]`
allowlist, such as `skipto`, `limit`, `missingstring`, `dateformat`,
`normalizenames`, `ignoreemptyrows`, `ignorerepeated`, `decimal`, or
`groupmark`.

`writeinc` does not infer or create `[structure]` metadata from CSV writing
keyword arguments. If a file needs structure metadata, provide it explicitly in
the metadata dictionary.
