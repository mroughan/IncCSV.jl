using CSV
using DataFrames
using IncCSV
using Test
using Tables

@testset "IncCSV" begin
    dir = mktempdir()
    example_dir = normpath(joinpath(@__DIR__, "..", "artifacts", "examples"))
    demo_inc = joinpath(example_dir, "demo.inc")
    plain_csv = joinpath(example_dir, "plain.csv")
    dataframe_inc = joinpath(example_dir, "dataframe.inc")
    commented_inc = joinpath(example_dir, "commented.inc")
    unicode_inc = joinpath(example_dir, "unicode.inc")
    unicode_delimiter_inc = joinpath(example_dir, "unicode_delimiter.inc")
    structured_semicolon_inc = joinpath(example_dir, "structured_semicolon.inc")
    structured_tsv_inc = joinpath(example_dir, "structured_tsv.inc")
    structured_pipe_inc = joinpath(example_dir, "structured_pipe.inc")
    default_schema_inc = joinpath(example_dir, "default_schema.inc")
    metadata_schema_inc = joinpath(example_dir, "metadata_schema.inc")
    missing_required_inc = joinpath(example_dir, "missing_required.inc")
    schema_examples_dir = normpath(joinpath(@__DIR__, "..", "artifacts", "schema_examples"))
    rows = [(name="Ada", score=21), (name="Babbage", score=12), (name="Church", score=14), (name="Dijkstra", score=15)]
    names = ["Ada", "Babbage", "Church", "Dijkstra"]
    scores = [21, 12, 14, 15]
    meta = Dict(
        "title" => "demo data",
        "source" => "unit test",
        "columns" => Dict("score" => "points"),
    )

    @testset "INC artifact" begin
        # Read a checked-in INC example with metadata and table data.
        file = readinc(demo_inc)
        columns = Tables.columntable(table(file))

        @test metadata(file)["title"] == "demo data"
        @test metadata(file)["source"] == "package artifact"
        @test metadata(file)["version"] == 1
        @test metadata(file)["offset"] == -3
        @test metadata(file)["columns"]["score"] == "points"
        @test columns.name == names
        @test columns.score == scores
        @test file.csv_start == 9
    end

    @testset "Plain CSV fallback" begin
        # Read a checked-in ordinary CSV example with empty metadata.
        plain_file = readinc(plain_csv)
        plain_columns = Tables.columntable(table(plain_file))

        @test isempty(metadata(plain_file))
        @test plain_columns.name == names
        @test plain_columns.score == scores
        @test plain_file.csv_start == 1
    end

    @testset "DataFrame sink" begin
        # Read a checked-in INC example directly into a DataFrame sink.
        dataframe_file = readinc(demo_inc, DataFrame)

        @test metadata(dataframe_file)["title"] == "demo data"
        @test table(dataframe_file) isa DataFrame
        @test table(dataframe_file).name == names
        @test table(dataframe_file).score == scores
    end

    @testset "DataFrame artifact" begin
        # Read a checked-in INC example whose expected table is a DataFrame.
        dataframe = DataFrame(name=["Hopper", "Hamilton"], score=[14, 15])
        dataframe_file = readinc(dataframe_inc, DataFrame)

        @test metadata(dataframe_file)["title"] == "dataframe artifact"
        @test metadata(dataframe_file)["source"] == "package artifact"
        @test metadata(dataframe_file)["columns"]["score"] == "points"
        @test table(dataframe_file) == dataframe
    end

    @testset "CSV keyword options" begin
        # Strip metadata comments locally and pass CSV comments to CSV.jl.
        file = readinc(commented_inc, DataFrame; comment="#")

        @test metadata(file)["title"] == "commented data"
        @test metadata(file)["source"] == "package artifact"
        @test metadata(file)["version"] == 2
        @test metadata(file)["offset"] == -5
        @test metadata(file)["string_number"] == "123"
        @test metadata(file)["columns"]["score"] == "points"
        @test table(file).name == names
        @test table(file).score == scores
    end

    @testset "Structure CSV options" begin
        # Use [structure] metadata to pass CSV.jl parsing options.
        file = readinc(structured_semicolon_inc, DataFrame)

        @test metadata(file)["title"] == "Semicolon-delimited data"
        @test metadata(file)["structure"]["delim"] == ";"
        @test table(file).name == ["Ada", "Babbage"]
        @test table(file).score == [21, 12]

        tsv_file = readinc(structured_tsv_inc, DataFrame)

        @test metadata(tsv_file)["title"] == "Tab-delimited data"
        @test metadata(tsv_file)["structure"]["delim"] == "tab"
        @test table(tsv_file).name == ["Ada", "Babbage"]
        @test table(tsv_file).score == [21, 12]

        pipe_file = readinc(structured_pipe_inc, DataFrame)

        @test metadata(pipe_file)["title"] == "Pipe-delimited data"
        @test metadata(pipe_file)["structure"]["delim"] == "|"
        @test table(pipe_file).name == ["Ada", "Babbage"]
        @test table(pipe_file).score == [21, 12]

        explicit_path = joinpath(dir, "explicit_delim_override.inc")
        write(
            explicit_path,
            "---\n" *
            "title = Explicit delimiter override\n" *
            "[structure]\n" *
            "delim = \";\"\n" *
            "---\n" *
            "name|score\n" *
            "Ada|21\n",
        )
        explicit_file = readinc(explicit_path, DataFrame; delim='|')

        @test metadata(explicit_file)["structure"]["delim"] == ";"
        @test table(explicit_file).name == ["Ada"]
        @test table(explicit_file).score == [21]
    end

    @testset "UTF-8 Unicode artifact" begin
        # Read Unicode metadata and CSV content from a checked-in UTF-8 file.
        file = readinc(unicode_inc, DataFrame)

        @test metadata(file)["title"] == "Café temperatures"
        @test metadata(file)["city"] == "München"
        @test metadata(file)["測定"] == "温度"
        @test metadata(file)["columns"]["temperature"] == "°C"
        @test metadata(file)["columns"]["名前"] == "participant name"
        @test table(file).name == ["Anaïs", "李", "Søren"]
        @test table(file).temperature == [21, 22, 19]
        @test table(file).note == ["café", "東京", "smørrebrød"]
    end

    @testset "Unicode dash delimiters" begin
        # Accept delimiters made from Unicode Punctuation, dash characters.
        artifact_file = readinc(unicode_delimiter_inc, DataFrame)

        @test metadata(artifact_file)["title"] == "Unicode dash delimiter"
        @test metadata(artifact_file)["source"] == "package artifact"
        @test table(artifact_file).name == ["Ada", "Babbage"]
        @test table(artifact_file).score == [21, 12]

        mixed_dash_path = joinpath(dir, "mixed_dash_delimiter.inc")
        write(
            mixed_dash_path,
            "‐–—\n" *
            "title = Mixed Unicode dash delimiter\n" *
            "‐–—\n" *
            "name,score\n" *
            "Ada,21\n",
        )
        mixed_file = readinc(mixed_dash_path, DataFrame)

        @test metadata(mixed_file)["title"] == "Mixed Unicode dash delimiter"
        @test table(mixed_file).name == ["Ada"]
        @test table(mixed_file).score == [21]
    end

    @testset "Metadata integer inference" begin
        # Infer only unquoted signed integers; keep other metadata as strings.
        path = joinpath(dir, "integer_metadata.inc")
        typed_meta = Dict(
            "positive" => 42,
            "negative" => -42,
            "string_number" => "42",
            "label" => "sample 42",
            "columns" => Dict("score" => "points", "rank" => 1),
        )
        writeinc(path, rows; metadata=typed_meta)
        file = readinc(path)

        @test metadata(file)["positive"] === 42
        @test metadata(file)["negative"] === -42
        @test metadata(file)["string_number"] == "42"
        @test metadata(file)["string_number"] isa String
        @test metadata(file)["label"] == "sample 42"
        @test metadata(file)["columns"]["rank"] === 1
        @test metadata(file)["columns"]["score"] == "points"
    end

    @testset "UTF-8 Unicode roundtrip" begin
        # Write and read Unicode metadata and CSV content as UTF-8 text.
        path = joinpath(dir, "unicode_roundtrip.inc")
        unicode_rows = DataFrame(name=["Zoë", "山田"], temperature=[18, 23], note=["naïve", "雪"])
        unicode_meta = Dict(
            "title" => "Résumé data",
            "city" => "Zürich",
            "測定" => "温度",
            "columns" => Dict("temperature" => "°C", "名前" => "name"),
        )

        writeinc(path, unicode_rows; metadata=unicode_meta)
        file = readinc(path, DataFrame)

        @test metadata(file)["title"] == "Résumé data"
        @test metadata(file)["city"] == "Zürich"
        @test metadata(file)["測定"] == "温度"
        @test metadata(file)["columns"]["temperature"] == "°C"
        @test metadata(file)["columns"]["名前"] == "name"
        @test table(file) == unicode_rows
    end

    @testset "Metadata type limits" begin
        # Reject metadata values outside the intentionally small type set.
        @test_throws ArgumentError writeinc(
            joinpath(dir, "float_metadata.inc"),
            rows;
            metadata=Dict("ratio" => 1.5),
        )
        @test_throws ArgumentError writeinc(
            joinpath(dir, "nested_float_metadata.inc"),
            rows;
            metadata=Dict("columns" => Dict("score" => 1.5)),
        )
    end

    @testset "Metadata mini-schema" begin
        # Validate MUST fields and report allowed-but-not-guaranteed extras.
        schema = readschema(metadata_schema_inc)

        @test schema.fields["title"].requirement == :must
        @test schema.fields["title"].type == "String"
        @test schema.fields["title"].description == "Human-readable dataset title"
        @test schema.fields["columns.score"].requirement == :must
        @test schema.fields["columns.score"].type == "String"
        @test schema.fields["city"].requirement == :maybe

        valid_report = validateschema(demo_inc, schema)

        @test valid_report.valid
        @test isempty(valid_report.missing)
        @test isempty(valid_report.extra)

        extra_report = validateschema(commented_inc, schema)

        @test extra_report.valid
        @test isempty(extra_report.missing)
        @test "string_number" in extra_report.extra

        missing_report = validateschema(missing_required_inc, schema)

        @test !missing_report.valid
        @test missing_report.missing == ["source"]
        @test isempty(missing_report.extra)
    end

    @testset "Default metadata schema" begin
        # Read the permissive default schema of common metadata terms.
        schema = readschema(default_schema_inc)

        @test schema.allow_extra
        @test isempty([path for (path, field) in schema.fields if field.requirement == :must])
        @test schema.fields["identifier"].requirement == :maybe
        @test schema.fields["identifier"].type == "IdentifierString"
        @test schema.fields["preservation.language"].type == "LanguageString"
        @test schema.fields["rights.license"].type == "LicenseString"
        @test schema.fields["structure.delim"].type == "CharacterString"
        @test schema.fields["parameters"].type == "section"
        @test schema.fields["statistical"].type == "section"
        @test schema.fields["process"].type == "section"
        @test schema.fields["title"].description == "Human-readable title of the resource"

        report = validateschema(demo_inc, schema)

        @test report.valid
        @test isempty(report.missing)
        @test "columns" in report.extra
    end

    @testset "Schema example suites" begin
        # Run the example scripts that validate folders of related INC files.
        restrictive = Base.include(Module(), joinpath(schema_examples_dir, "restrictive", "run.jl"))

        @test length(restrictive) == 3
        @test all(report -> report.valid, restrictive)
        @test all(report -> isempty(report.missing), restrictive)
        @test all(report -> isempty(report.extra), restrictive)
        @test all(report -> length(report.metadata_report) >= 7, restrictive)

        informational = Base.include(Module(), joinpath(schema_examples_dir, "informational", "run.jl"))

        @test length(informational) == 3
        @test all(report -> report.valid, informational)
        @test all(report -> isempty(report.missing), informational)
        @test any(report -> !isempty(report.extra), informational)

        balanced = Base.include(Module(), joinpath(schema_examples_dir, "balanced", "run.jl"))

        @test length(balanced) == 3
        @test all(report -> report.valid, balanced)
        @test all(report -> isempty(report.missing), balanced)
        @test any(report -> "priority" in report.extra, balanced)
        @test any(report -> "columns.status" in report.extra, balanced)
    end

    @testset "Closed metadata schema" begin
        # A schema can disallow metadata outside its MUST and MAYBE paths.
        schema = readschema(joinpath(schema_examples_dir, "restrictive", "schema.inc"))

        @test !schema.allow_extra

        closed_path = joinpath(dir, "closed_schema_extra.inc")
        write(
            closed_path,
            "---\n" *
            "title = Extra assay metadata\n" *
            "source = central lab\n" *
            "assay = glucose\n" *
            "version = 1\n" *
            "operator = Dr Extra\n" *
            "[columns]\n" *
            "sample_id = specimen identifier\n" *
            "value = measured concentration\n" *
            "[units]\n" *
            "value = mmol/L\n" *
            "---\n" *
            "sample_id,value\n" *
            "G-999,5.9\n",
        )
        report = validateschema(closed_path, schema)

        @test !report.valid
        @test isempty(report.missing)
        @test report.extra == ["operator"]
    end

    @testset "INC roundtrip" begin
        # Write and read a basic INC file created during the test.
        path = joinpath(dir, "example.inc")
        writeinc(path, rows; metadata=meta)
        file = readinc(path)
        columns = Tables.columntable(table(file))

        @test metadata(file)["title"] == "demo data"
        @test metadata(file)["source"] == "unit test"
        @test metadata(file)["columns"]["score"] == "points"
        @test columns.name == names
        @test columns.score == scores
        @test file.csv_start == 7
    end

    @testset "DataFrame source" begin
        # Write DataFrame rows and roundtrip them back through the DataFrame sink.
        dataframe_path = joinpath(dir, "dataframe.inc")
        dataframe = DataFrame(name=["Hopper", "Hamilton"], score=[14, 15])
        writeinc(dataframe_path, dataframe; metadata=meta)
        dataframe_roundtrip = readinc(dataframe_path, DataFrame)

        @test metadata(dataframe_roundtrip)["source"] == "unit test"
        @test metadata(dataframe_roundtrip)["columns"]["score"] == "points"
        @test table(dataframe_roundtrip) == dataframe
    end
end
