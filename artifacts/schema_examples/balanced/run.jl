using IncCSV
using Tables

function lookup_metadata(meta, path)
    haskey(meta, path) && return meta[path]
    parts = split(path, "."; limit=2)
    length(parts) == 2 || return missing
    section = get(meta, parts[1], nothing)
    section isa AbstractDict || return missing
    return get(section, parts[2], missing)
end

function schema_report(file, schema)
    meta = metadata(file)
    validation = validateschema(file, schema)
    paths = sort(collect(union(Set(keys(schema.fields)), Set(validation.extra))))

    rows = [
        (
            path=path,
            present=!ismissing(lookup_metadata(meta, path)),
            requirement=haskey(schema.fields, path) ? schema.fields[path].requirement : :extra,
            type=haskey(schema.fields, path) ? schema.fields[path].type : "",
            description=haskey(schema.fields, path) ? something(schema.fields[path].description, "") : "",
            value=lookup_metadata(meta, path),
        )
        for path in paths
    ]

    return (validation=validation, rows=rows)
end

function run_example(case_dir::AbstractString=@__DIR__)
    schema = readschema(joinpath(case_dir, "schema.inc"))
    files = sort(filter(name -> endswith(name, ".inc") && name != "schema.inc", readdir(case_dir)))

    return [
        begin
            path = joinpath(case_dir, name)
            file = readinc(path)
            report = schema_report(file, schema)
            (
                file=name,
                valid=report.validation.valid,
                missing=report.validation.missing,
                extra=report.validation.extra,
                rows=length(Tables.rowtable(table(file))),
                columns=collect(Tables.columnnames(table(file))),
                metadata_report=report.rows,
            )
        end
        for name in files
    ]
end

function print_report(reports)
    for report in reports
        println(report.file, ": valid=", report.valid, ", rows=", report.rows, ", extra=", report.extra)
    end
end

reports = run_example()
if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    print_report(reports)
end
reports
