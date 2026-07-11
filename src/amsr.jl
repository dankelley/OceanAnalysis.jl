is_numeric_vector(x) = isa(x, AbstractVector) && eltype(x) <: Number

"""
    read_amsr(filename::String, field::String="SST"; debug=0)

Reads a measurement stream from an AMSR file.

This returns a value of the [`Amsr`](@ref) type, with `metadata` containing the
`filename` along with vectors holding the `longitude` and `latitude` of the
grid and `data` holding a matrix of the data element with the indicated `name`.
Using `name="?"` sidesteps this process, instead returning a vector of strings
that may be given as `name` values.

# Arguments

- `filename`: a string indicating the location of the local file.

- `field`: a string used to identify the data field to be extracted.  If
  `field="?"` then `read_amsr` returns a vector of strings containing extractable
  data.  Otherwise, if `field` names one of those items, then `read_amsr` returns
  that dataset.

# Keywords

- `debug`: An indication of whether to print information during processing. The
  default value of 0 means to work quietly, and any larger integer indicates to
  print some information.


# Examples

```julia
# North Atlantic view, using turbo colour scheme
using OceanAnalysis, Plots
f = "~/data/amsr/RSS_AMSR2_ocean_L3_3day_2025-09-07_v08.2.nc";
d = read_amsr(f, "SST");
longitude = d.metadata["longitude"];
latitude = d.metadata["latitude"];
SST = d.data;
heatmap(longitude, latitude, SST, framestyle=:box,
    xlims=(290, 360), ylims=(20, 60),
    aspect_ratio=1/cos(pi*40/180),
    color=:turbo, size=(800, 550), dpi=300,
    title=f * ": SST", titlefontsize=9)
cl = coastline(:global_fine);
plot!(cl.data.longitude .+ 360, cl.data.latitude,
    seriestype=:shape, color=:bisque3, linewidth=0.8,
    legend=false)
```
"""
function read_amsr(filename::String, field::String="SST"; debug=0)
    filename = expanduser(filename)
    oad(debug, "read_amsr() BEGIN")
    NCDataset(filename, "r") do nc
        oad(debug, "    about to read SST")
        if field == "?"
            return keys(nc)
        else
            metadata = Dict()
            metadata["filename"] = filename
            metadata["longitude"] = copy(nc["lon"])
            metadata["latitude"] = copy(nc["lat"])
            metadata["field"] = field
            for a in ("sensor", "processing_level", "time_coverage_start",
                "time_coverage_end")
                metadata[a] = nc.attrib[a]
            end
            data = copy((Float64.(replace(nc[field], missing => NaN)))')
            oad(debug, "END read_amsr()")
            return Amsr(metadata, data)
        end
    end
end
export read_amsr


"""
    get_amsr(date::String)::String

"""
function get_amsr(date::String; kwargs...)::String
    get_amsr(Date(date), kwargs...)
end
export get_amsr

"""
    get_amsr(date::Date=Dates.today() - Day(4); type::String="3day",
        destdir::String=".", server::String="https://data.remss.com/amsr2/ocean/L3/v08.2",
        debug::Integer=0)

Download a Advanced Microwave Scanning Radiometer data file.

This works by constructing a filename to be downloaded. If that file does not
exist in `destdir`, then it is downloaded from the server, and `get_amsr`
returns the full path to that existing file. Otherwise, the file is downloaded,
and the return value is the path to the resultant local file.

For example, if this function is called on 2025-09-27 with no arguments
specified, an attempt will be made to download a file named
`"./RSS_AMSR2_ocean_L3_3day_2025-09-23_v08.2.nc"` from the server
[https://data.remss.com/amsr2/ocean/L3/v08.2/3day/2025/](https://data.remss.com/amsr2/ocean/L3/v08.2/3day/2025/).

See [`read_amsr`](@ref) for how to deal with the files downloaded
by `get_amsr`.

# Arguments

- `date` a Date object specifying the requested measurement time. The default value is 4 days prior to the present date.

# Keywords

- `destdir`: Path to the destination directory. The author usually sets
  `destdir="~/data/amsr"`, so that the file will be in a central location for use
  by other analysis procedures.

- `server`: The base of the server location. The default value ought to be used
  unless the data provider changes their web scheme, although the likelihood of
  the query working in such a case is slim, since changes tend to be sweeping.

- `type`: The type of data requested. At the moment, the only choice is
  `"3day"` (the default), for a composite covering 3 days of observation, which
  removes most viewing-path and cloud blanks. If there is sufficient need, other
  types may be added, from the list: `"daily"` for a daily reading, `"weekly"`
  for a composite covering a week, and `"monthly"` for a composite covering a
  month.  In the `"daily"` case, the data arrays are 3D, with the third dimension
  representing ascending and descending traces, but in all the other cases, the
  arrays are 2D.

- `debug`: An indication of whether to print information during processing. The
  default value of 0 means to work quietly, and any larger integer indicates to
  print some information.

# Return value

`get_amsr` returns a String that is the full pathname of the downloaded file,
which may be supplied as the first argument to a call to [`read_amsr`](@ref).
"""
function get_amsr(date::Date=Dates.today() - Dates.Day(4);
    type::String="3day",
    destdir::String=".", server::String="https://data.remss.com/amsr2/ocean/L3/v08.2",
    debug::Integer=0)::String
    oad(debug, "get_amsr() START")
    destfile = @sprintf(
        "RSS_AMSR2_ocean_L3_%s_%04d-%02d-%02d_v08.2.nc",
        type, year(date), month(date), day(date))
    destpath = expanduser(joinpath(destdir, destfile))
    oad(debug, "    destpath: '$destpath'")
    url = @sprintf("%s/%s/%d/%s", server, type, year(date), destfile)
    oad(debug, "    url: '$url'")
    if !isfile(destpath)
        oad(debug, "    downloading $url")
        Downloads.download(url, destpath)
    else
        oad(debug, "    $destpath has already been downloaded")
    end
    oad(debug, "END get_amsr()")
    destpath
end
export get_amsr


"""
    plot_amsr(amsr::Amsr; xlims=[0.0, 360.0], ylims=[-90.0, 90.0],
        draw_contours=:none, debug::Integer=0, kwargs...)
 
Plot a heatmap of an AMSR field.  By default, SST is shown using the `:turbo`
colorscheme, and the view is of the whole earth.

# Arguments

- `amsr`: An [`Amsr`](@ref) object, as read by [`read_amsr`](@ref).

# Keywords

- `xlims`: a tuple giving the range of longitude to be shown.  This is based on
  the 0 to 360 notation, since that is how AMSR data are stored.

- `ylims`: a tuple giving the range of latitude to be shown. THis is based on
  the -90 to 90 notation.

- `draw_contours`: either symbol a numeric vector that controls contours that
  may be added to the heatmap.  If this is `:none` (which is the default), then
  no contours are drawn. If it is `:auto` then contours are drawn at 5°C
  increments. And, finally, if it is a vector of numeric elements, then contours
  are drawn (unlabelled) at those values.

- `debug`: An integer controlling whether to print information during
  processing. The default is to work silently; use any positive value to get some
  printing.

- `kwargs...` optional other arguments to customize the heatmap plot. For
  example, specify a value for `color` to change the palette. Although it is
  permitted to set `aspect_ratio`, the default will yield correct shapes in the
  middle of the plot, which is likely the best approach.

# Examples

```julia
using OceanAnalysis
file = "~/data/amsr/RSS_AMSR2_ocean_L3_3day_2025-09-07_v08.2.nc"
amsr = read_amsr(file, "SST");
plot_amsr(amsr, xlims=(300,360), ylims=(40,60))
```
"""
function plot_amsr(amsr::Amsr; xlims=[0.0, 360.0], ylims=[-90.0, 90.0],
    draw_contours=:none, debug::Integer=0, kwargs...)
    2 == length(xlims) || throw(ArgumentError("xlims must be of length 2"))
    2 == length(ylims) || throw(ArgumentError("ylims must be of length 2"))
    oad(debug, "plot_amsr() START")
    oad(debug, "  xlims: $xlims, ylims: $ylims")
    longitude = amsr.metadata["longitude"]
    latitude = amsr.metadata["latitude"]
    oad(debug, "  plotting a heatmap of ", amsr.metadata["field"])
    p = heatmap(longitude, latitude, amsr.data,
        xlims=xlims, ylims=ylims,
        aspect_ratio=1.0 / cos(pi * 0.5 * (ylims[1] + ylims[2]) / 180.0),
        levels=range(-5.0, 35.0, step=5.0), color=:turbo, clim=:auto,
        framestyle=:box, tickdirection=:out; kwargs...)
    oad(debug, "  adding a coastline")
    cl = coastline(:global_fine)
    plot!(p, cl.data.longitude, cl.data.latitude,
        seriestype=:shape, color=:bisque3, linewidth=0.5,
        legend=false)
    if any(xlims .> 180.0)
        plot!(p, cl.data.longitude .+ 360, cl.data.latitude,
            seriestype=:shape, color=:bisque3, linewidth=0.5,
            legend=false)
    end
    # Possibly draw contours
    if draw_contours != :none
        if draw_contours == :auto
            oad(debug, "  adding auto-selected contours")
            contour!(p, longitude, latitude, amsr.data, levels=
                range(-5.0, 35.0, step=5.0), color=:black,
                linewidth=0.75)
        elseif is_numeric_vector(draw_contours)
            oad(debug, "  adding user-specified contours")
            contour!(p, longitude, latitude, amsr.data, levels=draw_contours, color=:black,
                linewidth=0.75)
        else
            @warn "draw_contours ($draw_contours) cannot be handled; try :none, :auto, or a numeric vector"
        end
    end
    oad(debug, "END plot_amsr()")
    p
end
export plot_amsr


"""
    subset_amsr(a::Amsr, lonlims, latlims; debug::Integer=0)

Subset an [`Amsr`](@ref) object to a specified longitude and latitude range.

# Arguments

- `a`: an [`Amsr`](@ref) object.

- `lonlims`: A numeric tuple of length 2 specifying the minimum and maximum longitude values to be retained.

- `latlims`: A numeric tuple of length 2 specifying the minimum and maximum latitude values to be retained.

- `debug`: An indication of whether to print information during processing. The default value of 0 means to work quietly, and any larger integer indicates to print some information.
"""
function subset_amsr(a::Amsr, lonlims, latlims; debug::Integer=0)
    oad(debug, "subset_amsr BEGIN")
    2 == length(lonlims) || throw(ArgumentError("lonlims must be a tuple of length 2"))
    2 == length(latlims) || throw(ArgumentError("latlims must be a tuple of length 2"))
    lonOK = lonlims[1] .<= a.metadata["longitude"] .<= lonlims[2]
    latOK = latlims[1] .<= a.metadata["latitude"] .<= latlims[2]
    metadata = copy(a.metadata)
    metadata["longitude"] = metadata["longitude"][lonOK]
    metadata["latitude"] = metadata["latitude"][latOK]
    data = copy(a.data)[latOK, lonOK]
    rval = Amsr(metadata, data)
    oad(debug, "    keeping ",
        round(100.0 * sum(lonOK) / length(lonOK), digits=2), "% of longitudes and ",
        round(100.0 * sum(latOK) / length(latOK), digits=2), "% of latitudes")
    oad(debug, "END subset_amsr()")
    rval
end
export subset_amsr

