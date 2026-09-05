using FileIO, JLD2

"""
    plot_section(section::Section, which="salinity";
        type=:contourf, xvar=:latitude, yvar=:pressure, debug::Integer=0, kwargs...)

# Arguments

- `section` a Section, as created with [`as_section`](@ref) or [`read_section`](@ref).

- `which` a String indicating the name of the hydrographic variable to be
  plotted. This must be present in each of the [`Ctd`](@ref) objects stored
  within the `section.data`.  Another requirement is that the section has been
  gridded, using [`grid_section`](@ref). The plotting is done with `contour`,
  `contourf` or `heatmap` as directed by the `type` argument. In each case,
  `kwargs...` is passed to the function to permit customization.  If
  `show_stations` is true, then `vline` is used to draw vertical lines indicating
  station locations. Note that case 2, [`section_is_gridded`](@ref) is called
  first to ensure that the section has been gridded with [`grid_section`](@ref),
  with an error being reported if not.

# Keywords

- `type` a Symbol indicating the type of plot. This may be `:contour` for
  simple contours, `:contourf` (the default) for filled contours, or `:heatmap`
  for an image.

- `xvar` either a Symbol (which must be one of `:distance`, `:latitude` or
  `:longitude`) or a Tuple with two elements the first being a label for the x
  axis and the second being a vector of values for x that correspond to the
  stations in `section.data`.  See the Examples for a case in which sampling time
  is used for the Tuple case.

- `yvar` a Symbol, the permitted values of which are `:depth` and `:pressure`.

- `show_stations` a Bool value indicating whether to draw vertical gray dotted
  lines to indicate station locations on cross-section diagrams.

- `debug`: an optional integer value that, if it exceeds 0, indicates that
  debugging output should be printed during processing.

- `kwargs`: optional items, passed down to lower-level plotting functions. For
  example, `size` controls the size of the plot, `xlim` and `ylim` control the
  viewing window, and `color` controls the colour.

# Examples

```julia
using OceanAnalysis, Plots
url = "https://cchdo.ucsd.edu/data/41926/90CT40_1_ct1.zip"; # exchange format
dir = get_section(url);
s = read_section(dir);
s.data = s.data[s["longitude"].< (-68.0)];
p1 = plot_stations(s, xlim=(-80, -65), ylim=(35, 43));
scale_bar(500);
# Note that we must grid to get the cross-section diagrams
sg = grid_section(s);
p2 = plot_section(sg, "salinity", ylim=(0, 2000));
p3 = plot_section(sg, "salinity", ylim=(0, 2000), xvar=("Time", sg["time"]));
l = @layout [a; b c];
plot(p1, p2, p3, layout=l, dpi=300, size=(800, 500))
```
"""
function plot_section(section::Section, which::String="salinity";
    type::Symbol=:contourf,
    xvar::Union{Symbol,Tuple}=:latitude,
    yvar=:pressure, show_stations::Bool=false,
    debug::Integer=0, kwargs...)
    error("plot_section() disabled, pending convertion from Plots to Makie")
    #<disabled>    oad(debug, "plot_section(which=\"$which\") BEGIN")
    #<disabled>    oad(debug, "  see if section is gridded")
    #<disabled>    section_is_gridded(section) || error("must use grid_section() on the section before plotting it")
    #<disabled>    # assume all CTDs have the same data-column names
    #<disabled>    fields = names(section.data[1].data)
    #<disabled>    which in fields || error("which=\"$which\" not allowed; try one of the following: ", fields)
    #<disabled>    type in (:contour, :contourf, :heatmap) || throw(ArgumentError("type=$(repr(type)) not allowed; try using :contour, :contourf or :heatmap"))
    #<disabled>    if xvar isa Symbol
    #<disabled>        oad(debug, "  xvar is a Symbol")
    #<disabled>        if xvar == :longitude
    #<disabled>            xlab = "Longitude [°E]"
    #<disabled>            x = section["longitude"]
    #<disabled>        elseif xvar == :latitude
    #<disabled>            xlab = "Latitude [°N]"
    #<disabled>            x = section["latitude"]
    #<disabled>        elseif xvar == :distance
    #<disabled>            xlab = "Distance [km]"
    #<disabled>            x = geod_distance.(section["longitude"], section["latitude"],
    #<disabled>                section["longitude"][1], section["latitude"][1])
    #<disabled>        else
    #<disabled>            error("xvar=$(repr(xvar)) not allowed; try :distance, :Latitude or :Longitude")
    #<disabled>        end
    #<disabled>    elseif xvar isa Tuple
    #<disabled>        oad(debug, "  xvar is a Tuple")
    #<disabled>        2 == length(xvar) || error("xvar is a Tuple, but its length is not 2")
    #<disabled>        x = xvar[2]
    #<disabled>        xlab = xvar[1]
    #<disabled>    else
    #<disabled>        error("xvar must be a Symbol or a Tuple")
    #<disabled>    end
    #<disabled>    if yvar == :depth
    #<disabled>        ylab = "Depth [m]"
    #<disabled>        y = section.data[1]["z"]
    #<disabled>    elseif yvar == :pressure
    #<disabled>        ylab = "Pressure [dbar]"
    #<disabled>        y = section.data[1]["pressure"]
    #<disabled>    elseif yvar == :z
    #<disabled>        ylab = "Vertical Coordinate [m]"
    #<disabled>        y = section.data[1]["depth"]
    #<disabled>    else
    #<disabled>        error("yvar=$(repr(yvar)) not allowed; try :depth, :pressure or :z")
    #<disabled>    end
    #<disabled>    oad(debug, "  set x=$(first(x,3)) (+ more) for yvar=$xvar")
    #<disabled>    oad(debug, "  set y=$(first(y,3)) (+ more) for yvar=$yvar")
    #<disabled>    oad(debug, "  assemble field for plotting")
    #<disabled>    nrows, ncols = length(section.data[1]["pressure"]), length(section.data)
    #<disabled>    z = zeros(nrows, ncols)
    #<disabled>    #println("size(z): $(size(z))")
    #<disabled>    for i in 1:ncols
    #<disabled>        rval = section.data[i][which]
    #<disabled>        #println("i=4i, size(rval): $(size(rval))")
    #<disabled>        z[:, i] = rval
    #<disabled>    end
    #<disabled>    levels = pretty(z, 12)
    #<disabled>    oad(debug, "  levels: $levels")
    #<disabled>    oad(debug, "  putting x and y (and z) in ascending order")
    #<disabled>    ix = sortperm(x)
    #<disabled>    iy = sortperm(y)
    #<disabled>    x = x[ix]
    #<disabled>    y = y[iy]
    #<disabled>    z = z[iy, ix]
    #<disabled>    # Kludge required for Julia as of 2025-12-30 (see link in the debug message)
    #<disabled>    # (Actually, I think this is only needed for heatmap.)
    #<disabled>    oad(debug, "  applying a patch to avoid a heatmap problem")
    #<disabled>    kw = (; kwargs...)
    #<disabled>    if haskey(kwargs, :ylim)
    #<disabled>        oad(debug, "  Avoiding heatmap() error handling ylim together with yflip=true; see")
    #<disabled>        oad(debug, "    https://discourse.julialang.org/t/heatmap-how-do-ylim-and-yflip-interact/134804/4")
    #<disabled>        oad(debug, "  for discussion.")
    #<disabled>        keep_y = kw[:ylim][1] .<= y .<= kw[:ylim][2]
    #<disabled>    else
    #<disabled>        keep_y = y .< Inf
    #<disabled>    end
    #<disabled>    y = y[keep_y]
    #<disabled>    z = z[keep_y, :]
    #<disabled>    # ok, now can plot
    #<disabled>
    #<disabled>    if type == :contour
    #<disabled>        oad(debug, "  using contour()")
    #<disabled>        pl = contour(x, y, z;
    #<disabled>            contourlabels=true, color=:black, cbar=false, levels=levels,
    #<disabled>            yflip=yvar == :pressure || yvar == :depth ? true : false,
    #<disabled>            xlab=xlab, ylab=ylab, framestyle=:box, tickdirection=:out,
    #<disabled>            titlefontsize=8, guidefontsize=8, tickfontsize=8, legendfontsize=8,
    #<disabled>            kwargs...)
    #<disabled>    elseif type == :contourf
    #<disabled>        oad(debug, "  using contourf()")
    #<disabled>        jldsave("dan.jld2"; x, y, z)
    #<disabled>        pl = contourf(x, y, z;
    #<disabled>            contourlabels=true, color=:turbo, cbar=false, levels=levels,
    #<disabled>            yflip=yvar == :pressure || yvar == :depth ? true : false,
    #<disabled>            xlab=xlab, ylab=ylab, framestyle=:box, tickdirection=:out,
    #<disabled>            titlefontsize=8, guidefontsize=8, tickfontsize=8, legendfontsize=8,
    #<disabled>            kwargs...)
    #<disabled>    elseif type == :heatmap
    #<disabled>        oad(debug, "  using heatmap()")
    #<disabled>        pl = heatmap(x, y, z;
    #<disabled>            yflip=yvar == :pressure || yvar == :depth ? true : false,
    #<disabled>            xlab=xlab, ylab=ylab, framestyle=:box, color=:turbo, tickdirection=:out,
    #<disabled>            titlefontsize=8, guidefontsize=8, tickfontsize=8, legendfontsize=8,
    #<disabled>            kwargs...)
    #<disabled>    else
    #<disabled>        error("type=$(repr(type)) not allowed; try :contour, :contourf or :heatmap")
    #<disabled>    end
    #<disabled>    if show_stations
    #<disabled>        oad(debug, "  drawing stations")
    #<disabled>        vline!(x, color=RGBA(0.5, 0.5, 0.5, 0.7), linewidth=1, linestyle=:dot, label=false)
    #<disabled>    end
    #<disabled>    oad(debug, "END plot_section()")
    #<disabled>    pl
end
export plot_section

