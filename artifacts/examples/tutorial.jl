using DataFrames
using IncCSV

function incsv_tutorial_report(example_dir::AbstractString=@__DIR__)
    demo = readinc(joinpath(example_dir, "demo.inc"), DataFrame)
    structured = readinc(joinpath(example_dir, "structured_tsv.inc"), DataFrame)
    schema = readschema(joinpath(example_dir, "default_schema.inc"))
    schema_report = validateschema(demo, schema)

    output_dir = mktempdir()
    output_path = joinpath(output_dir, "tutorial_output.inc")
    rows = DataFrame(time=[0, 1], temperature=[21, 22])

    writeinc(
        output_path,
        rows;
        metadata=Dict(
            "title" => "Tutorial output",
            "source" => "artifacts/examples/tutorial.jl",
            "columns" => Dict("temperature" => "Celsius"),
        ),
    )

    roundtrip = readinc(output_path, DataFrame)

    return (
        demo_title=metadata(demo)["title"],
        demo_rows=nrow(table(demo)),
        demo_score_units=metadata(demo)["columns"]["score"],
        structured_title=metadata(structured)["title"],
        structured_delim=metadata(structured)["structure"]["delim"],
        structured_rows=nrow(table(structured)),
        schema_valid=schema_report.valid,
        schema_extra=schema_report.extra,
        roundtrip_title=metadata(roundtrip)["title"],
        roundtrip_rows=nrow(table(roundtrip)),
        roundtrip_units=metadata(roundtrip)["columns"]["temperature"],
    )
end

function print_incsv_tutorial_report(report)
    println("demo: ", report.demo_title, " (", report.demo_rows, " rows)")
    println("structure example: ", report.structured_title, " uses delim = ", report.structured_delim)
    println("default schema valid: ", report.schema_valid)
    println("roundtrip: ", report.roundtrip_title, " (", report.roundtrip_rows, " rows)")
end

report = incsv_tutorial_report()

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    print_incsv_tutorial_report(report)
end

report
