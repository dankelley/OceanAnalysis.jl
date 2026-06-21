"""
    as_section(ctds::Vector{Ctd}; name::String="", source::String="", debug::Integer=0)

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
julia> f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv");
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
function as_section(ctds::Vector{Ctd}; debug::Integer=0)
    oad(debug, "as_section() START")
    nctds = length(ctds)
    nctds > 0 || throw(ArgumentError("ctds is empty"))
    metadata = Dict()
    data = Vector{Ctd}(undef, nctds)
    for i in 1:nctds
        oad(debug, "  save $i-th entry") # FIXME: maybe use a progress bar instead
        data[i] = ctds[i]
    end
    oad(debug, "END as_section()")
    Section(metadata, data)
end # as_section()


"""
    read_section(Section::s, debug::Integer=0)

Read an oceanographic section, as downloaded with [`get_section`](@ref).

This uses [`read_ctd_exchange`](@ref) to read WOCE-format CTD files in the
directory named `dir`. These are then aggregated into a section
using [`as_section`](@ref).

# Arguments

- `dir`: String naming a directory that holds WOCE-format CTD files.

# Keywords

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

# Examples
```julia
using OceanAnalysis, Plots
url = "https://cchdo.ucsd.edu/data/11852/ar07_74JC20140606_ct1.zip"
dir = get_section(url)
section = read_section(dir);
display(section.metadata)
println("Section contains ", length(section.data), " CTD profiles")
```
"""
function read_section(dir::String; debug::Integer=0)
    oad(debug, "read_section() START")
    files = readdir(dir)
    length(files) > 0 || throw(ArgumentError("no ctd files found in $dir"))
    # Reading typically takes about 7 ms per file
    ctds = map((file) -> read_ctd_exchange(joinpath(dir, file), debug=increment_debug(debug)), files)
    oad(debug, "  read $(length(ctds)) CTD files")
    rval = as_section(ctds)
    meta = ctds[1].metadata
    for transfer in ["section_id", "expocode"]
        if transfer in keys(meta)
            rval.metadata[transfer] = meta[transfer]
            oad(debug, "  inserted $transfer into section.metadata")
        end
    end
    rval.metadata["source"] = abspath(dir)
    oad(debug, "END read_section()")
    rval
end

"""
    section_is_gridded(Section:section; debug:Int64=0)

Return true if section is gridded (that is, if it has more than 1
CTD station, and if the pressure levels match across all the
CTD stations.
"""
function section_is_gridded(section::Section; debug::Integer=0)
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
            oad(debug, "  mismatch between section.data[1].pressure and section.data[$i].pressure")
            #println(pressure0)
            #println(pressure)
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
    grid_section(section::Section, pressure_step::Float64=2.0; debug::Integer=0)

Grid a section, altering all the CTD objects to employ a uniform pressure grid.

The pressure grid is set up to range from 0 to the maximum pressure across all
the CTDs in `section`, incrementing by `pressure_step`. Once this is set up,
the other fields are interpolated to this grid using linear interpolation, with
missing values inserted for gridded pressures that exceed the maximum value in
any given CTD.

# Arguments

- `section` a [`Section`](@ref) object.

- `pressure_step` desired pressure increment, in dbar.

# Keywords

- `debug`: an optional value that, if it exceeds 0, indicates that debugging output should be printed during processing.

# Examples

```julia
using OceanAnalysis
url = "https://cchdo.ucsd.edu/data/11852/ar07_74JC20140606_ct1.zip"
dir = get_section(url)
section = read_section(dir);
section_gridded = grid_section(section)
```

"""
function grid_section(section::Section, pressure_step::Float64=2.0; debug::Integer=0)
    oad(debug, "grid_section() START")
    oad(debug, "  setting up uniform pressure grid with pressure step $pressure_step")
    nctds = length(section.data)
    nctds > 0 || throw(ArgumentError("section must hold have at least 1 station"))
    metadata = section.metadata
    metadata["gridded"] = true
    data = Vector{Ctd}(undef, nctds)
    pressure_maximum = extrema(map(ctd -> extrema(ctd["pressure"])[2], section.data))[2]
    pressure_grid = range(0.0, pressure_maximum, step=pressure_step)
    oad(debug, "  interpolating data to this grid FIXME: NOT DONE YET")
    for i in eachindex(section.data)
        data[i] = grid_ctd(section.data[i], pressure_grid=pressure_grid, debug=debug)
    end
    oad(debug, "  constructing return value")
    rval = Section(metadata, data)
    oad(debug, "END grid_section()")
    rval
end
