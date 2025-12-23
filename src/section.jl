#<moved to src/plot.jl> """
#<moved to src/plot.jl>     plot_section(x, y, z, levels=:auto;
#<moved to src/plot.jl>         title="", xlab="Distance from Shore [km]", ylab="Pressure [db]", show_stations=true)
#<moved to src/plot.jl> 
#<moved to src/plot.jl> Draw an oceanographic section plot, with contours for z=z(x,y). This is a
#<moved to src/plot.jl> preliminary version of the function, subject to changes.  More documentation
#<moved to src/plot.jl> will be added later, after a period of real-world testing and modification.
#<moved to src/plot.jl> """
#<moved to src/plot.jl> function plot_section(x, y, z, levels=:auto;
#<moved to src/plot.jl>     title="", xlab="Distance from Shore [km]", ylab="Pressure [db]", show_stations=true)
#<moved to src/plot.jl>     if levels == :auto
#<moved to src/plot.jl>         levels = pretty(z, 10)
#<moved to src/plot.jl>     end
#<moved to src/plot.jl>     figure_size = (600, 400)
#<moved to src/plot.jl>     font_size = 10.0
#<moved to src/plot.jl>     rval = contour(x, y, z, yflip=true, color=:black,
#<moved to src/plot.jl>         xlab=xlab, ylab=ylab, title=title, titlelocation=:left,
#<moved to src/plot.jl>         framestyle=:box, levels=levels, cbar=false, clabels=true,
#<moved to src/plot.jl>         size=figure_size, tickdirection=:out,
#<moved to src/plot.jl>         titlefontsize=font_size, labelfontsize=font_size, tickfontsize=font_size, dpi=dpi)
#<moved to src/plot.jl>     if show_stations
#<moved to src/plot.jl>         xlim, ylim = xlims(), ylims()
#<moved to src/plot.jl>         for xx in x
#<moved to src/plot.jl>             plot!(repeat([xx], 2), collect(ylim), xlim=xlim, ylim=ylim,
#<moved to src/plot.jl>                 seriestype=:path, color=:lightgray, linewidth=0.5, grid=false, label=false)
#<moved to src/plot.jl>         end
#<moved to src/plot.jl>     end
#<moved to src/plot.jl>     rval
#<moved to src/plot.jl> end

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
