"""
    as_section(ctds::Vector{Ctd}; name::String="", source::String="", debug::Int64=0)

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
julia> # Create fake data
       f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv");
julia> a = read_ctd_cnv(f, add_teos=false);
julia> b = read_ctd_cnv(f, add_teos=false);
julia> b.data.salinity = 1.0 .+ b.data.salinity;
julia> s = as_section([a; b], name="Test");
julia> println("Section '"* s.metadata["name"] * "' has entries with salinities starting:")
Section 'Test' has entries with salinities starting:
julia> for i in 1:length(s.data)
           println(first(s.data[i].data.salinity,3))
       end
[29.921, 29.9205, 29.9206]
[30.921, 30.9205, 30.9206]
```
"""
function as_section(ctds::Vector{Ctd}; name::String="", source::String="", debug::Int64=0)
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


"""
    read_section(Section::s, debug::Int64=0)

Read an oceanographic section, as downloaded with [`get_section`](@ref).

This uses [`read_ctd_woce`](@ref) to read WOCE-format CTD files in the
directory named `dir`. These are then aggregated into a section
using [`as_section`](@ref).

# Arguments

- `dir`: String naming a directory that holds WOCE-format CTD files.

# Keywords

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

# Examples
```juliadoc
using OceanAnalysis, Plots
url = "https://cchdo.ucsd.edu/data/11852/ar07_74JC20140606_ct1.zip"
dir = get_section(url)
section = read_section(dir);
# Show station locations
plot(section, "map")
```
"""
function read_section(dir::String; debug::Int64=0)
    files = readdir(dir)
    length(files) > 0 || error("no ctd files found in $dir")
    # Reading typically takes about 7 ms per file
    ctds = map((file) -> read_ctd_woce(joinpath(dir, file)), files)
    as_section(ctds)
end

"""
    section_is_gridded(Section:section; debug:Int64=0)

Return true if section is gridded (that is, if it has more than 1
CTD station, and if the pressure levels match across all the
CTD stations.
"""
function section_is_gridded(section::Section; debug::Int64=0)
    oad(debug, "section_is_gridded() START")
    nctds = length(section.data)
    rval = true
    if nctds < 2
        oad(debug, "  section has <2 stations")
        rval = false
    end
    oad(debug, "  check that CTDs have equal pressures")
    pressure0 = section.data[1]["pressure"]
    for i in 2:nctds
        pressure = section.data[i]["pressure"]
        if pressure != pressure0
            oad(debug, "    pressure mismatch between first CTD and $i-th CTD; use grid_section() first")
            rval = false
            break
        end
    end
    status = rval ? "gridded" : "not gridded"
    oad(debug, "  section is $status")
    oad(debug, "END section_is_gridded()")
    rval
end

"""
    section_grid(section::Section; debug::Int64=0)

Grid a section, altering all the CTD objects to employ a uniform
z grid. This is done by linear interpolation.
FIXME: code as in oce
"""
function section_grid(section::Section; debug::Int64=0)
    oad(debug, "section_grid() START")
    oad(debug, "END section_grid()")
end
