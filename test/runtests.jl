using Aqua
using CSV
using DataFrames
using IncCSV
using JET
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
    parser_edge_cases_inc = joinpath(example_dir, "parser_edge_cases.inc")
    escaped_metadata_inc = joinpath(example_dir, "escaped_metadata.inc")
    structured_semicolon_inc = joinpath(example_dir, "structured_semicolon.inc")
    structured_tsv_inc = joinpath(example_dir, "structured_tsv.inc")
    structured_pipe_inc = joinpath(example_dir, "structured_pipe.inc")
    structured_quotechar_inc = joinpath(example_dir, "structured_quotechar.inc")
    structured_escapechar_inc = joinpath(example_dir, "structured_escapechar.inc")
    structured_delimiter_alias_inc = joinpath(example_dir, "structured_delimiter_alias.inc")
    structured_delimiter_precedence_inc = joinpath(example_dir, "structured_delimiter_precedence.inc")
    default_schema_inc = joinpath(example_dir, "default_schema.inc")
    metadata_schema_inc = joinpath(example_dir, "metadata_schema.inc")
    missing_required_inc = joinpath(example_dir, "missing_required.inc")
    tutorial_jl = joinpath(example_dir, "tutorial.jl")
    invalid_example_dir = normpath(joinpath(@__DIR__, "..", "artifacts", "invalid_examples"))
    schema_examples_dir = normpath(joinpath(@__DIR__, "..", "artifacts", "schema_examples"))
    rows = [(name="Ada", score=21), (name="Babbage", score=12), (name="Church", score=14), (name="Dijkstra", score=15)]
    names = ["Ada", "Babbage", "Church", "Dijkstra"]
    scores = [21, 12, 14, 15]
    demo_names = ["Ada", "Babbage", "Church", "Missing", "Dijkstra"]
    demo_scores = Union{Missing,Int}[21, 12, 14, missing, 15]
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
        @test metadata(file)["empty_field"] == ""
        @test metadata(file)["columns"]["score"] == "points"
        @test columns.name == demo_names
        @test isequal(columns.score, demo_scores)
        @test file.csv_start == 10
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
        @test table(dataframe_file).name == demo_names
        @test isequal(table(dataframe_file).score, demo_scores)
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

    @testset "Metadata parser edge cases" begin
        # Parse literal comment markers and escaped characters predictably.
        file = readinc(parser_edge_cases_inc, DataFrame)

        @test metadata(file)["title"] == "Parser edge cases"
        @test metadata(file)["semicolon"] == ";"
        @test metadata(file)["hash"] == "#"
        @test metadata(file)["commented"] == "value"
        @test metadata(file)["not_comment"] == "value#not comment"
        @test metadata(file)["backslash"] == "a\\;b"
        @test metadata(file)["quoted"] == "a # b; c \"q\" \\ slash"
        @test metadata(file)["section"]["key"] == "value"
        @test table(file).name == ["Ada"]
        @test table(file).score == [21]

        empty_section_path = joinpath(dir, "empty_section.inc")
        write(
            empty_section_path,
            "---\n" *
            "[empty]\n" *
            "---\n" *
            "name,score\n" *
            "Ada,21\n",
        )
        @test_throws ArgumentError readinc(empty_section_path)

        missing_close_path = joinpath(dir, "missing_closing_delimiter.inc")
        write(
            missing_close_path,
            "---\n" *
            "title = missing delimiter\n" *
            "[columns]\n" *
            "score = points\n",
        )
        err = try
            readinc(missing_close_path)
            nothing
        catch e
            e
        end

        @test err isa ArgumentError
        @test occursin(missing_close_path, sprint(showerror, err))
        @test occursin("line 4", sprint(showerror, err))
    end

    @testset "Invalid example artifacts" begin
        # Checked-in invalid examples each demonstrate one rejected behavior.
        invalid_readinc_files = [
            "empty_section.inc",
            "invalid_key.inc",
            "invalid_section_name.inc",
            "missing_closing_delimiter.inc",
            "repeated_key.inc",
            "invalid_section_key.inc",
            "structure_invalid_comment.inc",
            "structure_invalid_char.inc",
            "structure_invalid_int.inc",
            "unsupported_structure_key.inc",
        ]

        for name in invalid_readinc_files
            @test_throws ArgumentError readinc(joinpath(invalid_example_dir, name), DataFrame)
        end

        invalid_schema_files = [
            "schema_duplicate_requirement.inc",
            "schema_duplicate_alias_requirement.inc",
            "schema_deep_path.inc",
        ]

        for name in invalid_schema_files
            @test_throws ArgumentError readschema(joinpath(invalid_example_dir, name))
        end

        err = try
            readinc(joinpath(invalid_example_dir, "missing_closing_delimiter.inc"))
            nothing
        catch e
            e
        end

        @test err isa ArgumentError
        @test occursin("missing_closing_delimiter.inc", sprint(showerror, err))
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

        quote_file = readinc(structured_quotechar_inc, DataFrame)

        @test metadata(quote_file)["title"] == "Quote character data"
        @test metadata(quote_file)["structure"]["quotechar"] == "'"
        @test table(quote_file).note == ["hello, world"]

        escape_file = readinc(structured_escapechar_inc, DataFrame)

        @test metadata(escape_file)["title"] == "Escape character data"
        @test metadata(escape_file)["structure"]["escapechar"] == "|"
        @test table(escape_file).note == ["say \"hi\""]

        delimiter_file = readinc(structured_delimiter_alias_inc, DataFrame)

        @test metadata(delimiter_file)["title"] == "Delimiter alias data"
        @test metadata(delimiter_file)["structure"]["delimiter"] == ";"
        @test table(delimiter_file).name == ["Ada"]
        @test table(delimiter_file).score == [21]

        delimiter_precedence_file = readinc(structured_delimiter_precedence_inc, DataFrame)

        @test metadata(delimiter_precedence_file)["structure"]["delim"] == ","
        @test metadata(delimiter_precedence_file)["structure"]["delimiter"] == ";"
        @test table(delimiter_precedence_file).name == ["Ada"]
        @test table(delimiter_precedence_file).score == [21]

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

        header_path = joinpath(dir, "structure_header.inc")
        write(
            header_path,
            "---\n" *
            "title = Structure header option\n" *
            "[structure]\n" *
            "header = 2\n" *
            "---\n" *
            "discard,discard\n" *
            "name,score\n" *
            "Ada,21\n",
        )
        header_file = readinc(header_path, DataFrame)

        @test metadata(header_file)["structure"]["header"] == 2
        @test table(header_file).name == ["Ada"]
        @test table(header_file).score == [21]

        footer_path = joinpath(dir, "structure_footerskip.inc")
        write(
            footer_path,
            "---\n" *
            "title = Structure footerskip option\n" *
            "[structure]\n" *
            "footerskip = 1\n" *
            "---\n" *
            "name,score\n" *
            "Ada,21\n" *
            "Babbage,12\n" *
            "TOTAL,33\n",
        )
        footer_file = readinc(footer_path, DataFrame)

        @test metadata(footer_file)["structure"]["footerskip"] == 1
        @test table(footer_file).name == ["Ada", "Babbage"]
        @test table(footer_file).score == [21, 12]

        skipto_path = joinpath(dir, "structure_skipto_rejected.inc")
        write(
            skipto_path,
            "---\n" *
            "title = Structure skipto rejected\n" *
            "[structure]\n" *
            "skipto = 2\n" *
            "---\n" *
            "name,score\n" *
            "Ada,21\n",
        )

        @test_throws ArgumentError readinc(skipto_path, DataFrame)

        limit_path = joinpath(dir, "structure_limit_rejected.inc")
        write(
            limit_path,
            "---\n" *
            "title = Structure limit rejected\n" *
            "[structure]\n" *
            "limit = 1\n" *
            "---\n" *
            "name,score\n" *
            "Ada,21\n",
        )

        @test_throws ArgumentError readinc(limit_path, DataFrame)
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

    @testset "Metadata writer validation" begin
        # Write only metadata the reader can parse back safely.
        artifact_file = readinc(escaped_metadata_inc, DataFrame)

        @test metadata(artifact_file)["path"] == "C:\\tmp\\file"
        @test metadata(artifact_file)["quote"] == "say\"hi"
        @test metadata(artifact_file)["columns"]["note"] == "\"quoted\" value"
        @test table(artifact_file).name == ["Ada"]
        @test table(artifact_file).score == [21]

        path = joinpath(dir, "escaped_metadata.inc")
        escaped_meta = Dict(
            "quote" => "say\"hi",
            "slash" => "back\\slash",
            "columns" => Dict("path" => "C:\\tmp\\file", "quote" => "\"unit\""),
        )
        writeinc(path, rows; metadata=escaped_meta)
        file = readinc(path)

        @test metadata(file)["quote"] == "say\"hi"
        @test metadata(file)["slash"] == "back\\slash"
        @test metadata(file)["columns"]["path"] == "C:\\tmp\\file"
        @test metadata(file)["columns"]["quote"] == "\"unit\""

        ordered_path = joinpath(dir, "ordered_metadata.inc")
        ordered_meta = Dict(
            "z" => 1,
            "a" => 2,
            "bsec" => Dict("z" => 1, "a" => 2),
            "asec" => Dict("b" => 2, "a" => 1),
        )
        writeinc(ordered_path, rows; metadata=ordered_meta)
        ordered_lines = readlines(ordered_path)

        @test ordered_lines[1:11] == [
            "---",
            "a = 2",
            "z = 1",
            "[asec]",
            "a = 1",
            "b = 2",
            "",
            "[bsec]",
            "a = 2",
            "z = 1",
            "---",
        ]

        @test_throws ArgumentError writeinc(joinpath(dir, "newline_metadata.inc"), rows; metadata=Dict("note" => "a\nb"))
        @test_throws ArgumentError writeinc(joinpath(dir, "invalid_key_metadata.inc"), rows; metadata=Dict("bad key" => "value"))
        @test_throws ArgumentError writeinc(joinpath(dir, "invalid_section_metadata.inc"), rows; metadata=Dict("bad=section" => Dict("key" => "value")))
        @test_throws ArgumentError writeinc(joinpath(dir, "invalid_section_key_metadata.inc"), rows; metadata=Dict("section" => Dict("bad key" => "value")))
        @test_throws ArgumentError writeinc(joinpath(dir, "empty_section_metadata.inc"), rows; metadata=Dict("section" => Dict{String,String}()))
    end

    @testset "Metadata mini-schema" begin
        # Validate MUST fields and report allowed-but-not-guaranteed extras.
        schema = readschema(metadata_schema_inc)

        @test schema.fields["title"].requirement == :must
        @test schema.fields["title"].type == "String"
        @test schema.fields["title"].description == "Human-readable dataset title"
        @test schema.fields["columns.score"].requirement == :must
        @test schema.fields["columns.score"].type == "String"
        @test schema.fields["city"].requirement == :optional
        @test schema.fields["empty_field"].requirement == :optional
        @test schema.fields["password"].requirement == :must_not
        @test schema.fields["password"].description == "Secrets must not be stored as file metadata"

        valid_report = validateschema(demo_inc, schema)

        @test valid_report.valid
        @test isempty(valid_report.missing)
        @test isempty(valid_report.extra)
        @test isempty(valid_report.forbidden)

        extra_report = validateschema(commented_inc, schema)

        @test extra_report.valid
        @test isempty(extra_report.missing)
        @test "string_number" in extra_report.extra
        @test isempty(extra_report.forbidden)

        missing_report = validateschema(missing_required_inc, schema)

        @test !missing_report.valid
        @test missing_report.missing == ["source"]
        @test isempty(missing_report.extra)
        @test isempty(missing_report.forbidden)

        forbidden_path = joinpath(dir, "forbidden_schema_field.inc")
        write(
            forbidden_path,
            "---\n" *
            "title = Forbidden metadata\n" *
            "source = unit test\n" *
            "password = secret\n" *
            "[columns]\n" *
            "score = points\n" *
            "---\n" *
            "name,score\n" *
            "Ada,21\n",
        )
        forbidden_report = validateschema(forbidden_path, schema)

        @test !forbidden_report.valid
        @test isempty(forbidden_report.missing)
        @test isempty(forbidden_report.extra)
        @test forbidden_report.forbidden == ["password"]
    end

    @testset "Schema validation edge cases" begin
        # Reject ambiguous schemas and treat declared child paths as declaring their parent section.
        duplicate_path = joinpath(dir, "duplicate_schema_field.inc")
        write(
            duplicate_path,
            "---\n" *
            "[MUST]\n" *
            "title = String\n" *
            "[OPTIONAL]\n" *
            "title = String\n" *
            "---\n",
        )
        @test_throws ArgumentError readschema(duplicate_path)

        duplicate_alias_path = joinpath(dir, "duplicate_schema_alias_field.inc")
        write(
            duplicate_alias_path,
            "---\n" *
            "[REQUIRED]\n" *
            "title = String\n" *
            "[SHALL]\n" *
            "title = String\n" *
            "---\n",
        )
        @test_throws ArgumentError readschema(duplicate_alias_path)

        deep_path = joinpath(dir, "deep_schema_field.inc")
        write(
            deep_path,
            "---\n" *
            "[MUST]\n" *
            "a.b.c = String\n" *
            "---\n",
        )
        @test_throws ArgumentError readschema(deep_path)

        parent_schema_path = joinpath(dir, "parent_section_schema.inc")
        write(
            parent_schema_path,
            "---\n" *
            "[schema]\n" *
            "allow_extra = false\n" *
            "[MUST]\n" *
            "columns.score = String\n" *
            "---\n",
        )
        parent_file_path = joinpath(dir, "parent_section_file.inc")
        write(
            parent_file_path,
            "---\n" *
            "[columns]\n" *
            "score = points\n" *
            "---\n" *
            "name,score\n" *
            "Ada,21\n",
        )
        report = validateschema(parent_file_path, readschema(parent_schema_path))

        @test report.valid
        @test isempty(report.missing)
        @test isempty(report.extra)
        @test isempty(report.forbidden)
    end

    @testset "RFC 2119 schema aliases" begin
        # Accept read-only aliases while storing canonical requirement symbols.
        alias_schema_path = joinpath(dir, "rfc_2119_alias_schema.inc")
        write(
            alias_schema_path,
            "---\n" *
            "[REQUIRED]\n" *
            "title = String\n" *
            "[SHALL]\n" *
            "source = String\n" *
            "[SHALL_NOT]\n" *
            "password = String\n" *
            "[MAY]\n" *
            "city = String\n" *
            "[description]\n" *
            "source = Where the data came from\n" *
            "password = Secrets must not be stored as file metadata\n" *
            "---\n",
        )
        schema = readschema(alias_schema_path)

        @test schema.fields["title"].requirement == :must
        @test schema.fields["source"].requirement == :must
        @test schema.fields["source"].description == "Where the data came from"
        @test schema.fields["password"].requirement == :must_not
        @test schema.fields["city"].requirement == :optional

        report = validateschema(demo_inc, schema)

        @test report.valid
        @test isempty(report.missing)
        @test isempty(report.forbidden)
    end

    @testset "Default metadata schema" begin
        # Read the permissive default schema of common metadata terms.
        schema = readschema(default_schema_inc)

        @test schema.allow_extra
        @test isempty([path for (path, field) in schema.fields if field.requirement == :must])
        @test schema.fields["identifier"].requirement == :optional
        @test schema.fields["identifier"].type == "IdentifierString"
        @test schema.fields["preservation.language"].type == "LanguageString"
        @test schema.fields["rights.license"].type == "LicenseString"
        @test schema.fields["structure.delim"].type == "CharacterString"
        @test schema.fields["structure.header"].type == "Int"
        @test schema.fields["parameters"].type == "section"
        @test schema.fields["statistical"].type == "section"
        @test schema.fields["process"].type == "section"
        @test schema.fields["title"].description == "Human-readable title of the resource"

        report = validateschema(demo_inc, schema)

        @test report.valid
        @test isempty(report.missing)
        @test "columns" in report.extra
        @test isempty(report.forbidden)
    end

    @testset "INC summary" begin
        # Summarise metadata and table shape for display or quick inspection.
        summary = summarise(demo_inc, DataFrame)

        @test summary isa IncSummary
        @test summary.source == demo_inc
        @test summary.title == "demo data"
        @test summary.rows == 5
        @test summary.columns == ["name", "score"]
        @test summary.csv_start == 10
        @test summary.metadata_fields == ["columns", "columns.score", "empty_field", "offset", "source", "title", "version"]

        text = sprint(printsummary, summary)

        @test occursin("INC summary", text)
        @test occursin("title: demo data", text)
        @test occursin("rows: 5", text)
        @test occursin("columns: name, score", text)
        @test endswith(text, "\n")

        file_summary = summarise(readinc(plain_csv, DataFrame))

        @test file_summary.source === nothing
        @test file_summary.title === nothing
        @test file_summary.rows == 4
        @test file_summary.metadata_fields == String[]
        @test occursin("metadata fields: (none)", sprint(printsummary, file_summary))
    end

    @testset "Examples tutorial" begin
        # Run the tutorial script and check the values it reports.
        tutorial = Base.include(Module(), tutorial_jl)

        @test tutorial.demo_title == "demo data"
        @test tutorial.demo_rows == 5
        @test tutorial.demo_score_units == "points"
        @test tutorial.demo_summary isa IncSummary
        @test tutorial.demo_summary.rows == 5
        @test tutorial.structured_title == "Tab-delimited data"
        @test tutorial.structured_delim == "tab"
        @test tutorial.structured_rows == 2
        @test tutorial.schema_valid
        @test "columns" in tutorial.schema_extra
        @test tutorial.roundtrip_title == "Tutorial output"
        @test tutorial.roundtrip_rows == 2
        @test tutorial.roundtrip_units == "Celsius"
    end

    @testset "Schema example suites" begin
        # Run the example scripts that validate folders of related INC files.
        restrictive = Base.include(Module(), joinpath(schema_examples_dir, "restrictive", "run.jl"))

        @test length(restrictive) == 3
        @test all(report -> report.valid, restrictive)
        @test all(report -> isempty(report.missing), restrictive)
        @test all(report -> isempty(report.extra), restrictive)
        @test all(report -> isempty(report.forbidden), restrictive)
        @test all(report -> length(report.metadata_report) >= 7, restrictive)

        informational = Base.include(Module(), joinpath(schema_examples_dir, "informational", "run.jl"))

        @test length(informational) == 3
        @test all(report -> report.valid, informational)
        @test all(report -> isempty(report.missing), informational)
        @test all(report -> isempty(report.forbidden), informational)
        @test any(report -> !isempty(report.extra), informational)

        balanced = Base.include(Module(), joinpath(schema_examples_dir, "balanced", "run.jl"))

        @test length(balanced) == 3
        @test all(report -> report.valid, balanced)
        @test all(report -> isempty(report.missing), balanced)
        @test all(report -> isempty(report.forbidden), balanced)
        @test any(report -> "priority" in report.extra, balanced)
        @test any(report -> "columns.status" in report.extra, balanced)
    end

    @testset "Closed metadata schema" begin
        # A schema can disallow metadata outside its MUST, MUST_NOT, and OPTIONAL paths.
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
        @test isempty(report.extra)
        @test report.forbidden == ["operator"]
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

    @testset "Code quality" begin
        # Run package-level hygiene checks and static analysis.
        Aqua.test_all(IncCSV)
        JET.test_package(IncCSV; target_modules=(IncCSV,))
    end
end
