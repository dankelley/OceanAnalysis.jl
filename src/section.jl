"""
    as_section(ctds; name="", source="", debug=0)

Construct a Section object, which olds one or more Ctd objects.

Returns a Section object with a `data` element that is a vector
of Ctd objects, along with a `metadata` element that holds
the `name` of the section and the `source` of the data.

# Arguments

- `ctds`: Vector of Ctd objects.

# Keywords

- `name`: the name of the section, often an 'EXPOCODE'.

- `source`: an indication of the data source, often a URL.

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

# Examples
```julia
julia> using OceanAnalysis

julia> # Create fake data (with S and T varying between stations)
       f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv");

julia> a = read_ctd_cnv(f, add_teos=false);

julia> b = read_ctd_cnv(f, add_teos=false);

julia> b.data.salinity = 1.0 .+ b.data.salinity;

julia> b.data.temperature = 1.0 .+ b.data.temperature;

julia> s = as_section((a, b), name="Test");

julia> println("Section \""* s.metadata["name"] * "\" has entries with data starting:")
Section "Test" has entries with data starting:

julia> for i in 1:length(s.data)
           println(first(s.data[i].data, 2))
       end
2×10 DataFrame
 Row │ salinity  temperature  pressure  scan     timeS    pr       depS     t090     sal00    flag
     │ Float64   Float64      Float64   Float64  Float64  Float64  Float64  Float64  Float64  Float64
─────┼────────────────────────────────────────────────────────────────────────────────────────────────
   1 │  29.921       14.2245     1.48     130.0    129.0    1.48     1.468  14.2245  29.921       0.0
   2 │  29.9205      14.2299     1.671    131.0    130.0    1.671    1.657  14.2299  29.9205      0.0
2×10 DataFrame
 Row │ salinity  temperature  pressure  scan     timeS    pr       depS     t090     sal00    flag
     │ Float64   Float64      Float64   Float64  Float64  Float64  Float64  Float64  Float64  Float64
─────┼────────────────────────────────────────────────────────────────────────────────────────────────
   1 │  30.921       15.2245     1.48     130.0    129.0    1.48     1.468  14.2245  29.921       0.0
   2 │  30.9205      15.2299     1.671    131.0    130.0    1.671    1.657  14.2299  29.9205      0.0
```
"""
function as_section(ctds; name="", source="", debug=0)
    oad(debug, "as_section() START")
    nctds = length(ctds)
    nctds > 0 || error("  as_section() provided with zero-length first argument")
    metadata = Dict()
    metadata["name"] = name
    metadata["source"] = source
    data = Vector{Ctd}(undef, nctds)
    for i in 1:nctds
        oad(debug, "  save $i-th entry") # FIXME: maybe use a progress bar instead
        data[i] = ctds[i]
    end
    oad(debug, "END as_section()")
    Section(metadata, data)
end # as_section()
