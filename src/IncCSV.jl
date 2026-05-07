module IncCSV

using CSV
using Tables

import DataAPI: metadata

export IncFile, IncSchema, SchemaValidation, metadata, table, readinc, readschema, validateschema, writeinc

"""
    IncFile(metadata, table; csv_start=1)

Container returned by [`readinc`](@ref).

An `IncFile` stores the parsed metadata, the table returned by CSV.jl, and the
line number where the CSV component starts. Use [`metadata`](@ref) and
[`table`](@ref) to access the two main pieces.

# Fields

- `metadata`: dictionary of top-level metadata values and one-level sections.
- `table`: the parsed CSV table, such as a `CSV.File` or `DataFrame`.
- `csv_start`: 1-based line number of the CSV header or first CSV row.
"""
struct IncFile{M,T}
    metadata::M
    table::T
    csv_start::Int
end

IncFile(metadata, table; csv_start::Integer=1) = IncFile(metadata, table, Int(csv_start))

"""
    IncSchema(fields; allow_extra=true)

A lightweight schema for INC metadata.

Schemas are read from ordinary INC metadata blocks using [`readschema`](@ref).
Each schema field has a path, a requirement level (`:must` or `:maybe`), a type
descriptor string, and optional descriptive text. Type descriptors are recorded
for humans and downstream tools; IncCSV does not parse metadata values beyond
its normal `Int`/`String` inference.

By default, metadata fields not described by the schema are allowed. If
`allow_extra` is `false`, validation fails when a file includes metadata outside
the schema's `MUST` and `MAYBE` fields.
"""
struct IncSchema
    fields::Dict{String,NamedTuple{(:requirement, :type, :description),Tuple{Symbol,String,Union{Nothing,String}}}}
    allow_extra::Bool
end

"""
    SchemaValidation(valid, missing, extra)

Validation report returned by [`validateschema`](@ref).

- `valid` is `true` when all `MUST` schema fields are present.
- `missing` lists required field paths that were not found.
- `extra` lists metadata field paths found in the file but not described by the schema.

Extra fields do not make a file invalid unless the schema has
`allow_extra=false`.
"""
struct SchemaValidation
    valid::Bool
    missing::Vector{String}
    extra::Vector{String}
end

"""
    metadata(file::IncFile)

Return the metadata dictionary parsed from an INC file.

Top-level metadata keys map to strings or integers. Section metadata maps to a
nested dictionary. Unquoted signed integer values are parsed as `Int`; quoted
values and all other values are returned as `String`. The parsed metadata type
is `Dict{String,Union{Int,String,Dict{String,Union{Int,String}}}}`.

# Example

```julia
file = readinc("example.inc")
metadata(file)["title"]
metadata(file)["columns"]["temperature"]
```
"""
metadata(file::IncFile) = file.metadata

"""
    table(file::IncFile)

Return the CSV table parsed from an INC file.

For `readinc(path)` this is a `CSV.File`. For `readinc(path, sink)`, this is the
table produced by `CSV.read(path, sink; ...)`, such as a `DataFrame`.

# Example

```julia
file = readinc("example.inc", DataFrame)
table(file)
```
"""
table(file::IncFile) = file.table

const MetadataValue = Union{Int,String}
const MetadataSection = Dict{String,MetadataValue}
const Metadata = Dict{String,Union{MetadataValue,MetadataSection}}

isdelimiter(line::AbstractString) = occursin(r"^\s*\p{Pd}{3,}\s*(?:[#;].*)?$", line)

function strip_comment(line::AbstractString)
    inquote = false
    escaped = false

    for (i, ch) in pairs(line)
        if escaped
            escaped = false
        elseif ch == '\\'
            escaped = true
        elseif ch == '"'
            inquote = !inquote
        elseif !inquote && (ch == '#' || ch == ';')
            i == firstindex(line) && return ""
            return line[firstindex(line):prevind(line, i)]
        end
    end

    return line
end

function parse_value(value::AbstractString)
    value = strip(value)
    if startswith(value, "\"") && endswith(value, "\"") && ncodeunits(value) >= 2
        value = value[nextind(value, firstindex(value)):prevind(value, lastindex(value))]
        return replace(value, "\\\"" => "\"", "\\\\" => "\\")
    end

    if occursin(r"^[+-]?\d+$", value)
        parsed = tryparse(Int, value)
        parsed === nothing || return parsed
    end

    return String(value)
end

function parse_metadata(lines)
    result = Metadata()
    current = result
    section_names = Set{String}()

    for (line_number, rawline) in enumerate(lines)
        line = strip(strip_comment(rawline))
        isempty(line) && continue

        if startswith(line, "[") && endswith(line, "]")
            section = String(strip(line[nextind(line, firstindex(line)):prevind(line, lastindex(line))]))
            isempty(section) && throw(ArgumentError("empty metadata section at line $line_number"))
            occursin(r"[\[\]=#;\s]", section) &&
                throw(ArgumentError("invalid metadata section '$section' at line $line_number"))
            in(section, section_names) &&
                throw(ArgumentError("repeated metadata section '$section' at line $line_number"))

            nested = MetadataSection()
            result[section] = nested
            push!(section_names, section)
            current = nested
        else
            parts = split(line, "="; limit=2)
            length(parts) == 2 || throw(ArgumentError("invalid metadata line '$rawline' at line $line_number"))

            key = String(strip(parts[1]))
            isempty(key) && throw(ArgumentError("empty metadata key at line $line_number"))
            occursin(r"[\[\]=#;\s]", key) &&
                throw(ArgumentError("invalid metadata key '$key' at line $line_number"))
            haskey(current, key) &&
                throw(ArgumentError("repeated metadata key '$key' at line $line_number"))

            current[key] = parse_value(parts[2])
        end
    end

    return result
end

function split_inc(path::AbstractString)
    metadata_lines = String[]
    csv_start = 1

    io = open(path, "r")
    try
        eof(io) && return Metadata(), 1
        line = readline(io)
        isdelimiter(line) || return Metadata(), 1
        csv_start += 1

        while !eof(io)
            line = readline(io)

            if isdelimiter(line)
                return parse_metadata(metadata_lines), csv_start + 1
            end

            push!(metadata_lines, line)
            csv_start += 1
        end
    finally
        close(io)
    end

    throw(ArgumentError("INC metadata block is missing its closing delimiter"))
end

function getsection(meta::AbstractDict, names...)
    for name in names
        for (key, value) in meta
            lowercase(key) == lowercase(name) && value isa AbstractDict && return value
        end
    end

    return MetadataSection()
end

function schemafield(requirement::Symbol, type, description)
    type isa String ||
        throw(ArgumentError("schema type descriptors must be strings"))
    description === nothing || description isa String ||
        throw(ArgumentError("schema descriptions must be strings"))

    return (requirement=requirement, type=type, description=description)
end

function parse_schema_bool(value, name)
    if value isa Int
        value == 1 && return true
        value == 0 && return false
    elseif value isa String
        normalized = lowercase(strip(value))
        normalized in ("true", "yes", "allow", "allowed", "1") && return true
        normalized in ("false", "no", "deny", "closed", "0") && return false
    end

    throw(ArgumentError("schema option '$name' must be true or false"))
end

"""
    readschema(path)

Read a lightweight metadata schema from an INC-style metadata block.

The schema file reuses INC metadata syntax and normally contains these sections:

```text
---
[MUST]
title = String
columns.score = String

[MAYBE]
version = Int

[description]
title = Human-readable title
columns.score = Units or meaning of the score column
---
```

The optional `[schema]` section can set schema-level behavior:

```text
[schema]
allow_extra = false
```

`allow_extra` defaults to `true`. When it is `false`, files containing metadata
fields outside `[MUST]` and `[MAYBE]` fail validation.

Keys in `[MUST]` and `[MAYBE]` are metadata field paths. Top-level metadata uses
plain names such as `title`; section entries use dotted paths such as
`columns.score`; a section itself can be described with a path such as
`columns` and a descriptor such as `section`.

Values in `[MUST]` and `[MAYBE]` are type descriptor strings. They may be more
specific than `Int` or `String`; IncCSV records them but does not parse strings
according to those descriptors.
"""
function readschema(path::AbstractString)
    meta, _ = split_inc(path)
    must = getsection(meta, "MUST", "must", "required")
    maybe = getsection(meta, "MAYBE", "maybe", "optional")
    descriptions = getsection(meta, "description", "descriptions", "describe")
    options = getsection(meta, "schema", "options")
    allow_extra = haskey(options, "allow_extra") ? parse_schema_bool(options["allow_extra"], "allow_extra") : true
    fields = Dict{String,NamedTuple{(:requirement, :type, :description),Tuple{Symbol,String,Union{Nothing,String}}}}()

    for (path, type) in must
        fields[path] = schemafield(:must, type, get(descriptions, path, nothing))
    end

    for (path, type) in maybe
        fields[path] = schemafield(:maybe, type, get(descriptions, path, nothing))
    end

    return IncSchema(fields, allow_extra)
end

function fieldpaths(meta::AbstractDict)
    paths = String[]

    for (key, value) in meta
        if value isa AbstractDict
            push!(paths, key)
            append!(paths, ["$key.$section_key" for section_key in keys(value)])
        else
            push!(paths, key)
        end
    end

    return sort(paths)
end

function hasfieldpath(meta::AbstractDict, path::AbstractString)
    haskey(meta, path) && return true
    parts = split(path, "."; limit=2)

    if length(parts) == 2
        section = get(meta, parts[1], nothing)
        return section isa AbstractDict && haskey(section, parts[2])
    end

    return false
end

"""
    validateschema(metadata, schema::IncSchema)
    validateschema(file::IncFile, schema::IncSchema)
    validateschema(path, schema::IncSchema)

Validate INC metadata against a lightweight schema.

Validation checks that every `[MUST]` field in the schema is present. `[MAYBE]`
fields are documented but optional. Additional metadata fields are returned in
`SchemaValidation.extra`. They are allowed by default, but make validation fail
when `schema.allow_extra == false`.

Type descriptors are not enforced by IncCSV. They are carried by the schema for
humans and downstream tools that may want richer parsing.
"""
function validateschema(meta::AbstractDict, schema::IncSchema)
    required = sort([path for (path, field) in schema.fields if field.requirement == :must])
    known = Set(keys(schema.fields))
    actual = fieldpaths(meta)
    missing = [path for path in required if !hasfieldpath(meta, path)]
    extra = [path for path in actual if !(path in known)]

    return SchemaValidation(isempty(missing) && (schema.allow_extra || isempty(extra)), missing, extra)
end

validateschema(file::IncFile, schema::IncSchema) = validateschema(metadata(file), schema)

function validateschema(path::AbstractString, schema::IncSchema)
    meta, _ = split_inc(path)
    return validateschema(meta, schema)
end

const STRUCTURE_CHAR_KEYS = Set([:delim, :quotechar, :escapechar, :decimal, :groupmark])
const STRUCTURE_STRING_KEYS = Set([:comment, :missingstring, :dateformat])
const STRUCTURE_BOOL_KEYS = Set([:ignoreemptyrows, :ignorerepeated, :normalizenames])
const STRUCTURE_INT_KEYS = Set([:header, :skipto, :footerskip, :limit])

function structure_char(value, key)
    value isa Int && return Char(value)

    if value isa String
        normalized = lowercase(strip(value))
        normalized == "tab" && return '\t'
        normalized == "\\t" && return '\t'
        normalized == "space" && return ' '
        length(value) == 1 && return only(value)
    end

    throw(ArgumentError("structure.$key must be a single character, 'tab', or 'space'"))
end

function structure_bool(value, key)
    if value isa Int
        value == 1 && return true
        value == 0 && return false
    elseif value isa String
        normalized = lowercase(strip(value))
        normalized in ("true", "yes", "1") && return true
        normalized in ("false", "no", "0") && return false
    end

    throw(ArgumentError("structure.$key must be true or false"))
end

function structure_kwarg_value(key::Symbol, value)
    key in STRUCTURE_CHAR_KEYS && return structure_char(value, key)
    key in STRUCTURE_STRING_KEYS && value isa String && return value
    key in STRUCTURE_STRING_KEYS && throw(ArgumentError("structure.$key must be a string"))
    key in STRUCTURE_BOOL_KEYS && return structure_bool(value, key)
    key in STRUCTURE_INT_KEYS && value isa Int && return value

    if key in STRUCTURE_INT_KEYS
        throw(ArgumentError("structure.$key must be an integer"))
    end

    throw(ArgumentError("unsupported structure keyword '$key'"))
end

function structure_csvkwargs(meta::AbstractDict)
    structure = getsection(meta, "structure")
    kwargs = Dict{Symbol,Any}()

    for (key, value) in structure
        kwargs[Symbol(key)] = structure_kwarg_value(Symbol(key), value)
    end

    return kwargs
end

function csv_options(meta::AbstractDict, csv_start::Integer, csvkwargs)
    kwargs = structure_csvkwargs(meta)

    for (key, value) in pairs(csvkwargs)
        kwargs[key] = value
    end

    if !haskey(kwargs, :header) && !haskey(kwargs, :skipto)
        kwargs[:header] = csv_start
    end

    names = Tuple(keys(kwargs))
    return NamedTuple{names}(Tuple(kwargs[name] for name in names))
end

"""
    readinc(path; csvkwargs...)
    readinc(path, sink; csvkwargs...)

Read an INC file and return an [`IncFile`](@ref).

The metadata component is parsed by IncCSV. The CSV component is read by CSV.jl.
Without `sink`, the table is a `CSV.File`. With `sink`, IncCSV delegates to
`CSV.read`; for example `readinc(path, DataFrame)` returns an `IncFile` whose
table is a `DataFrame`.

Plain CSV files are accepted and returned with empty metadata.

CSV.jl keyword options are forwarded to the CSV reader. By default, IncCSV sets
the CSV header line to the first line after the closing metadata delimiter. If
you pass `header` or `skipto` yourself, your explicit CSV.jl options are used.

INC files can also include a `[structure]` metadata section to provide CSV.jl
reader options for the CSV component. Supported keys are `delim`, `quotechar`,
`escapechar`, `decimal`, `groupmark`, `comment`, `missingstring`, `dateformat`,
`ignoreemptyrows`, `ignorerepeated`, `normalizenames`, `header`, `skipto`,
`footerskip`, and `limit`. Explicit keyword arguments passed to `readinc`
override `[structure]` values.

# Examples

```julia
file = readinc("example.inc")
metadata(file)["title"]
table(file)
```

```julia
using DataFrames

file = readinc("example.inc", DataFrame; comment="#")
table(file) isa DataFrame
```
"""
function readinc(path::AbstractString; csvkwargs...)
    meta, csv_start = split_inc(path)
    data = CSV.File(path; csv_options(meta, csv_start, csvkwargs)...)
    return IncFile(meta, data; csv_start)
end

function readinc(path::AbstractString, sink; csvkwargs...)
    meta, csv_start = split_inc(path)
    data = CSV.read(path, sink; csv_options(meta, csv_start, csvkwargs)...)
    return IncFile(meta, data; csv_start)
end

function escape_value(value)
    text = string(value)
    needs_quotes = value isa AbstractString &&
        (isempty(text) || occursin(r"^\s|\s$|[#;=\[\]\n\r]|^[+-]?\d+$", text))
    text = replace(text, "\\" => "\\\\", "\"" => "\\\"")
    return needs_quotes ? "\"$text\"" : text
end

function validate_metadata_value(key, value)
    value isa Int && return value
    value isa String && return value
    throw(ArgumentError("metadata value for '$key' must be an Int or String"))
end

function validate_metadata(meta::AbstractDict)
    result = Metadata()

    for (key, value) in meta
        key isa String || throw(ArgumentError("metadata keys must be strings"))

        if value isa AbstractDict
            section = MetadataSection()
            for (section_key, section_value) in value
                section_key isa String || throw(ArgumentError("metadata section keys must be strings"))
                section[section_key] = validate_metadata_value("$key.$section_key", section_value)
            end
            result[key] = section
        else
            result[key] = validate_metadata_value(key, value)
        end
    end

    return result
end

function write_metadata(io::IO, meta::AbstractDict)
    meta = validate_metadata(meta)

    println(io, "---")

    for (key, value) in meta
        value isa AbstractDict && continue
        println(io, key, " = ", escape_value(value))
    end

    wrote_section = false
    for (section, values) in meta
        values isa AbstractDict || continue
        wrote_section && println(io)
        println(io, "[", section, "]")
        for (key, value) in values
            println(io, key, " = ", escape_value(value))
        end
        wrote_section = true
    end

    println(io, "---")
end

"""
    writeinc(path, rows; metadata=Dict(), csvkwargs...)

Write an INC file and return `path`.

`metadata` is written as a small INI-style block delimited by `---` lines. The
CSV component is written by `CSV.write`, so any Tables.jl-compatible input can
be used, including a `DataFrame`.

Metadata values must be `Int` or `String`. Metadata sections must be one-level
dictionaries whose values are also `Int` or `String`.

String values that look like integers are quoted so they roundtrip as strings.
Integer values are written unquoted and are read back as `Int`.

CSV.jl keyword options are forwarded to `CSV.write`.

# Example

```julia
rows = [(time=0, temperature=21), (time=1, temperature=22)]

writeinc(
    "example.inc",
    rows;
    metadata=Dict(
        "title" => "Example data",
        "version" => 1,
        "columns" => Dict("temperature" => "Celsius"),
    ),
)
```
"""
function writeinc(path::AbstractString, rows; metadata=Metadata(), csvkwargs...)
    Tables.istable(rows) || throw(ArgumentError("rows must be a Tables.jl-compatible table"))

    open(path, "w") do io
        write_metadata(io, metadata)
    end

    CSV.write(path, rows; append=true, header=true, csvkwargs...)

    return path
end

end
