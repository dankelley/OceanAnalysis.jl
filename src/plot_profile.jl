"""
    plot_profile(d; which::String="CT", vertical::Symbol=:pressure,
        color_by=false, abbreviate::Symbol=:long, fontsize=8,
        debug::Integer=0, kwargs...)

    plot_profile!(fig_pos, d; which::String="CT", vertical::Symbol=:pressure,
        color_by=false, abbreviate::Symbol=:long, fontsize=8,
        debug::Integer=0, kwargs...)

Plot an oceanographic profile for data contained in `d`, showing how the
variable named by `which` depends on either pressure or density.  The variable
is drawn on the x axis and either sigma0 or pressure on the y axis; in both
cases, the waters nearer the surface are shown nearer the top of the plot.

The `plot_profile()` function creates a single plot. The `plot_profile!()`
function adds to an existing plot.  See the Examples section
for illustrations of both cases.

These functions require a Makie backend to be loaded and activated by
the caller (e.g. `using CairoMakie` or `using GLMakie`) before they
are called.

# Arguments

- `fig_pos` a Figure object created with the Makie function
  [`Figure`](@ref). This is used for mutating case, i.e. a
  case using `plot_profile!() as opposed to `plot_profile()`.

- `d` either an Argo object or a Ctd object.

# Keywords

- `which` an indication of what to plot on the x axis. The default value,
  `"CT"`, indicates to plot Conservative Temperature. Anything stored in the
  object's `data` can be plotted, along with some things that can be calculated
  from these values. Common choices include: `"N2"` for N², the square of the
  buoyancy frequency; `"SA"` for the Gibbs Seawater formulation of Absolute
  Salinity; `"salinity"` for Practical Salinity; `"sigma0"` for the Gibbs
  Seawater formulation of density anomaly referenced to the surface;
  `"spiciness0"` for the Gibbs Seawater seawater spiciness referenced to the
  surface; and `"temperature"` for in-situ temperature.

- `vertical` a Symbol specifying what to plot on the y axis. The default is
  `:pressure`, but `:density` is also permitted.

- `color_by` a control on whether points on the plot are to be colorized
  individually according to some specified value. Four choices are
  possible. (1) If `color_by=false`, then all the data points are painted
  with the same `color`. (2) If `color_by` is a string naming a column
  in `d.data`, then colors are selected to show variation of the named
  variable.  (3) If `color_by` is a NamedTuple as created by
  [`decode_color_by`](@ref), then the variable may be in `ctd.data`
  but it may also be a numeric vector of appropriate length. Furthermore,
  in this choice the user can set the colorscheme and the spacing
  between the main plot and the palette. (4) And, finally,
  if `color_by=""` then the points are not colorized, and no
  palette is drawn, but space set aside to the right of the plot,
  where a palette would otherwise go.

- `abbreviate` a Symbol indicating a category for axis length, used in
  determining how to label the axes. The valid choices are `:short`, `:medium`,
  and `:long`.

- `debug` indicator of debugging level. If this exceeds 0, some information is
  printed during processing.

- `kwargs...` extra arguments that are parsed and handled accordingly. If
  `seriestype` is supplied, it controls how the data are illustrated; the
  possible values are `:scatter` (the default), `:lines` and `:scatterlines`. As
  with other functions in the package, you may use `fontsize` to set the sizes of
  text being displayed.  The other entries for `kwargs` follow Makie conventions,
  apart from a slight variation to `limits`, which here defaults to showing
  a little whitespace around the data span. To learn about `kwargs`
  entries that apply to the plot you're trying to make, call the
  functions with `debug=1`, which will print out entries as they
  are extracted from `kwargs`.

# Return value

The `plot_profile` form returns a `Makie.Figure`, which can be displayed
directly or saved with `save("filename.png", fig)`.

The `plot_profile!` form returns a NamedTuple containing `ax` (a `Makie.Axis`),
`plt` (a Makie `Lines`, `Scatter` or `Scatterlines` object) and `cb` (a
`Colorbar` object if `color_by` is a String, or `nothing` if `color_by=false` or
`color_by=""`).

# Examples
```julia
using OceanAnalysis, Plots

# Get data used in examples.
pkgdir = dirname(dirname(pathof(OceanAnalysis)))
f = joinpath(pkgdir, "data", "D4902911_095.nc")
ctd = read_argo(f) |> as_ctd;

# Example 1: Conservative Temperature profile for Argo data.
# Plot profiles of Conservative Temperature, Absolute Salinity, and potential
# density anomaly with respect to surface pressure.
fig = plot_profile(ctd; which="CT")
fig # display the results
# save("plot_profile_example_1.png", fig)

# Example 2: Two-panels, showing as above, but also a second
# panel in which dots are coloured to indicate Absolute
# Salinity.  The first argument in these calls indicates
# where to place things; `1,1` means row 1 and column 1,
# and `1,2` means row 1 and column 2. Thus, this plots
# a black-dot panel on the left and a coloured-dot panel
# on the right.
fig = Figure()
plot_profile!(fig[1,1], ctd; which="CT")
plot_profile!(fig[1,2], ctd; which="CT", color_by="SA")
fig # display the result
# save("plot_profile_example_2.png", fig)
```
"""
function plot_profile(d; which::String="CT", vertical::Symbol=:pressure,
    color_by=false, abbreviate::Symbol=:long, debug::Integer=0, kwargs...)
    oad(debug, "plot_profile() BEGIN (this calls plot_profile!() after creating a Figure")
    fig = Figure()
    plot_profile!(fig[1, 1], d; which=which, vertical=vertical,
        color_by=color_by, abbreviate=abbreviate,
        debug=increment_debug(debug), kwargs...)
    oad(debug, "END plot_profile()")
    return fig
end
export plot_profile


function plot_profile!(fig_pos, d; which::String="CT", vertical::Symbol=:pressure,
    abbreviate::Symbol=:long, color_by=false,
    debug::Integer=0, kwargs...)
    # This test might be useful if further customization is needed for a future version
    # of the package. For now, it simply makes for better debugging output.
    if isa(d, Argo)
        oad(debug, "plot_profile!(::Argo; which='$which', ...) START")
    elseif isa(d, Ctd)
        oad(debug, "plot_profile!(::Ctd; which='$which', ...) START")
    else
        error("plot_profile() only works on Argo and Ctd objects")
    end
    # For all cases, we need to set up the vertical axis, so do that first
    oad(debug, "    setting up coordinate system for vertical axis")
    if vertical == :pressure
        y = d["pressure"]
        ylabel = label_from_varname("p", abbreviate)
    elseif vertical == :density
        y = d["sigma0"]
        ylabel = label_from_varname("sigma0", abbreviate)
    else
        error("vertical must be either :pressure or :density")
    end
    x = get_element(d, which, debug=increment_debug(debug))
    if isnothing(x)
        error("plot_profile() cannot find (or compute a value for) \"$which\"")
    end
    using_color_by = false
    if color_by != false
        if isa(color_by, String)
            oad(debug, "    color_by: \"", color_by, "\"")
            if color_by in names(d.data)
                color_by = decode_color_by(d[color_by])
                #oad(debug, "    ... decoded palette details with decode_color_by()")
                cindex = (color_by.levels .- color_by.clims[1]) / (color_by.clims[2] - color_by.clims[1])
                #oad(debug, "    ... computed cindex")
                colormap = cgrad(color_by.colorscheme)
                #oad(debug, "    ... computed colormap")
                color = colormap[cindex]
                #oad(debug, "    ... computed color")
            elseif color_by == ""
                oad(debug, "    no palette will be drawn, since color_by=\"\"")
            else
                error("color_by is \"", color_by, "\" which is neither \"\" nor in names(d.data)")
            end
        elseif isa(color_by, NamedTuple)
            if length(color_by.levels) != nrow(d.data)
                error("length(color_by.levels)=", length(color_by.levels), " ≠ nrow(d.data)=", nrow(d.data))
            end
        else
            error("color_by must be 'false', a String, or a NamedTuple")
        end
        using_color_by = true
    end
    kwargs_dict = Dict{Symbol,Any}(kwargs)
    fontsize = pop!(kwargs_dict, :fontsize, 8)
    oad(debug, "    fontsize: $fontsize")
    if using_color_by
        oad(debug, "    set up color_by vector")
    else
        color = pop!(kwargs_dict, :color, :black)
    end
    title = pop!(kwargs_dict, :title, "")
    oad(debug, "    title: $title")
    xlabel = pop!(kwargs_dict, :xlabel, label_from_varname(which))
    oad(debug, "    xlabel: $xlabel")
    ylabel = pop!(kwargs_dict, :ylabel, ylabel)
    oad(debug, "    ylabel: $ylabel")
    linewidth = pop!(kwargs_dict, :linewidth, 1.0)
    ax = Axis(fig_pos[1, 1],
        xaxisposition=:top,
        title=title,
        xlabel=xlabel,
        ylabel=ylabel,
        yreversed=true,
        xlabelsize=fontsize, ylabelsize=fontsize, titlesize=fontsize,
        xticklabelsize=fontsize, yticklabelsize=fontsize)
    lims = pop!(kwargs_dict, :limits,
        (extend_extrema(skipmissing(x))...,
            reverse(extend_extrema(skipmissing(y)))...))
    oad(debug, "    limits: $lims")
    limits!(ax, lims...)
    linewidth = pop!(kwargs_dict, :linewidth, 1.0)
    oad(debug, "    linewidth=$linewidth")
    colormap = pop!(kwargs_dict, :colormap, :turbo)
    if using_color_by
        oad(debug, "    will use colormap :$colormap for color_by")
        typeof(color) == Vector{ColorTypes.RGBA{Float64}} || error("programming error: color_by did not set 'color' correctly")
    else
        color = pop!(kwargs_dict, :color, :black)
        oad(debug, "    set color=$color")
    end
    marker = pop!(kwargs_dict, :marker, :circle)
    oad(debug, "    marker=$marker")
    markercolor = pop!(kwargs_dict, :markercolor, :black)
    oad(debug, "    markercolor=$markercolor")
    markersize = pop!(kwargs_dict, :markersize, 5.0)
    oad(debug, "    markersize=$markersize")
    seriestype = pop!(kwargs_dict, :seriestype, :scatterlines)
    oad(debug, "    seriestype=$seriestype")
    seriestype in (:lines, :scatter, :scatterlines) || error("seriestype is '$seriestype', but it must be :line, :scatter or :scatterline")
    if !isempty(kwargs_dict)
        error("plot_profile!() does not recognize keywords: ",
            join(string.(keys(kwargs_dict)), ", "),
            ". The permitted keywords are: color, colormap, fontsize, linewidth, ",
            "marker, markercolor, markersize, seriestype, title, xlabel, ylabel.")
    end
    if seriestype == :lines
        oad(debug, "    calling lines!() with extra arguments as follows")
        oad(debug, "      • linewidth=$linewidth")
        if isa(color, Symbol) || isa(color, String)
            oad(debug, "      • color=$color")
        else
            oad(debug, "      • color: an object of type $(typeof(color))) and length $(length(color))")
        end
        plt = lines!(ax, x, y, linewidth=linewidth, color=color)
    elseif seriestype == :scatter
        oad(debug, "    calling scatter!() with extra arguments as follows")
        oad(debug, "      • marker=$marker")
        oad(debug, "      • markersize=$markersize")
        oad(debug, "      • markercolor=$markercolor")
        if isa(color, Symbol) || isa(color, String)
            oad(debug, "      • color=$color")
        else
            oad(debug, "      • color: an object of type $(typeof(color))) and length $(length(color))")
        end
        plt = scatter!(ax, x, y, marker=marker, markersize=markersize, color=color)
    elseif seriestype == :scatterlines
        oad(debug, "    calling scatterlines!() with extra arguments as follows")
        oad(debug, "      • marker=$marker")
        oad(debug, "      • markersize=$markersize")
        oad(debug, "      • markercolor=$markercolor")
        oad(debug, "      • linewidth=$linewidth")
        if isa(color, Symbol) || isa(color, String)
            oad(debug, "      • color=$color")
        else
            oad(debug, "      • color: an object of type $(typeof(color))) and length $(length(color))")
        end
        plt = scatterlines!(ax, x, y, marker=marker, markersize=markersize, markercolor=markercolor,
            linewidth=linewidth, color=color)
    else
        error("seriestype=$seriestype not permitted; try :lines, :scatter or :scatterlines")
    end
    cb = nothing
    if using_color_by
        oad(debug, "    drawing colorbar")
        cb = Colorbar(fig_pos[1, 2], colormap=colormap, limits=color_by.clims, ticklabelsize=fontsize)
        if color_by == ""
            cb.visible = false
        end
    end
    oad(debug, "END plot_profile!()")
    return (ax=ax, plt=plt, cb=cb)
end
export plot_profile!

