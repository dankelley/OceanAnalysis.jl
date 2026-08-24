is_numeric_vector(x) = isa(x, AbstractVector) &&
                       (eltype(x) <: Union{Missing,<:Real})

function average_amsr_passes(pass1, pass2)
    n = 0
    s = 0.0
    if !ismissing(pass1) && isfinite(pass1)
        s += float(pass1)
        n += 1
    end
    if !ismissing(pass2) && isfinite(pass2)
        s += float(pass2)
        n += 1
    end
    return n == 0 ? NaN : s / n
end


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
            return sort(collect(keys(nc)))
        end
        if !haskey(nc, field)
            error("There is no field '$field' in file. The possibilities are $(sort(collect(keys(nc))))")
        end
        oad(debug, "    setting up metadata")
        metadata = Dict()
        metadata["filename"] = filename
        metadata["longitude"] = Float64.(vec(nc["lon"][:]))
        metadata["latitude"] = Float64.(vec(nc["lat"][:]))
        metadata["field"] = field
        for a in ("sensor", "processing_level", "time_coverage_start", "time_coverage_end")
            metadata[a] = get(nc.attrib, a, missing)
        end
        oad(debug, "    setting up data")
        tmp = Array(nc[field][:])
        oad(debug, "    size of nc[field]: $(size(tmp))")
        if ndims(tmp) == 2
            arr = permutedims(Float64.(coalesce.(tmp, NaN)))
        else
            oad(debug, "    averaging ascending and descending passes")
            tmp2 = average_amsr_passes.(tmp[:, :, 1], tmp[:, :, 2])
            arr = permutedims(Float64.(coalesce.(tmp2, NaN)))
        end
        rval = Amsr(metadata, copy(arr))
        oad(debug, "END read_amsr()")
        return rval
    end
end
export read_amsr

"""
    get_amsr(date::Date=Dates.today(); type::String="3day", destdir::String=".",
        server::String="https://data.remss.com/amsr2/ocean/L3/v08.2", debug::Integer=0)::String

Download a Advanced Microwave Scanning Radiometer data file.

This works by constructing a filename to be downloaded. If that file does not
exist in `destdir`, then it is downloaded from the server, and `get_amsr`
returns the full path to that existing file. Otherwise, the file is downloaded,
and the return value is the path to the resultant local file.

If the date is not specified, it defaults to today's date.  To avoid errors of the
server not yet having data for that time, `get_amsr` shifts the time backwards,
depending on `type`, in an attempt to get the most recent data.  If these
shifts are insufficient, an error will be reported. The solution is to
specify an appropriate date, and for that purpose it makes sense for the
user to visit https://data.remss.com/amsr2/ocean/L3/v08.2 and then select
the subdirectory with a name that suggests the desired `type`.

See [`read_amsr`](@ref) for how to deal with the files downloaded
by `get_amsr`.

For code-maintenance reference, the following are sample URLs (valid as of 2026-08-23) for
the four possible values of `type`:
* `"daily"`: https://data.remss.com/amsr2/ocean/L3/v08.2/daily/2026/RSS_AMSR2_ocean_L3_daily_2026-08-20_v08.2.nc
* `"3day"`: https://data.remss.com/amsr2/ocean/L3/v08.2/3day/2026/RSS_AMSR2_ocean_L3_3day_2026-08-20_v08.2.nc
* `"monthly"`: https://data.remss.com/amsr2/ocean/L3/v08.2/monthly/RSS_AMSR2_ocean_L3_monthly_2026-06_v08.2.nc
* `"weekly"`: https://data.remss.com/amsr2/ocean/L3/v08.2/weekly/RSS_AMSR2_ocean_L3_weekly_2026-08-08_v08.2.nc

# Arguments

- `date` a Date object specifying the requested measurement time. The default
  value is today's date (see above for how that will be shifted to the past,
  depending on `type`.)

# Keywords

- `type`: The type of data requested, with default `"3day"`.
  If `type="daily"` then data from a single day are acquired, and
  this will typically leave quite a few gaps for clouds, as well
  satellite-coverage gaps. It is advisable to use
  [`plot_amsr`](@ref) to see whether the gaps affect
  the area of interest. If they do, try the default,
  i.e. `type="3day"`, for a composite covering 3 days of
  observation, which will average over most spatial-coverage
  and cloud gaps. If more averaging is desired, use
  `type="weekly"` or `type="monthly"`, but be aware that
  many time-varying features will be smeared with these averages.
  Also, note that for `"weekly"` data, the date is always
  a Sunday.

- `destdir`: Path to the destination directory. The author usually sets
  `destdir="~/data/amsr"`, so that the file will be in a central location for use
  by other analysis procedures.

- `server`: The base of the server location. The default value ought to be used
  unless the data provider changes their web scheme, although the likelihood of
  the query working in such a case is slim, since changes tend to be sweeping.
  Users are asked to report an issue, if they encounter failed server responses.

- `debug`: An indication of whether to print information during processing. The
  default value of 0 means to work quietly, and any larger integer indicates to
  print some information.

# Return value

`get_amsr` returns a String that is the full pathname of the downloaded file,
which may be supplied as the first argument of [`read_amsr`](@ref). In
many cases, the goal may be to plot the data, and for that, [`plot_amsr`](@ref)
may prove useful.
"""
function get_amsr(date::Date=Dates.today(); type::String="3day", destdir::String=".",
    server::String="https://data.remss.com/amsr2/ocean/L3/v08.2", debug::Integer=0)::String
    oad(debug, "get_amsr() START")
    oad(debug, "    date=\"$date\"")
    oad(debug, "    type=\"$type\"")
    oad(debug, "    destdir=\"$destdir\"")
    oad(debug, "    server=\"$server\"")
    if type == "daily"
        if date == Dates.today()
            date = date - Dates.Day(3) # FIXME: will 3 days always work, at any time of day?
        end
        # https://data.remss.com/amsr2/ocean/L3/v08.2/daily/2026/RSS_AMSR2_ocean_L3_daily_2026-08-20_v08.2.nc
        destfile = "RSS_AMSR2_ocean_L3_$(type)_$(year(date))-$(lpad(month(date), 2, '0'))-$(lpad(day(date), 2, '0'))_v08.2.nc"
        url = @sprintf("%s/%s/%d/%s", server, type, year(date), destfile)
        url = "$(server)/$(type)/$(year(date))/$destfile"
    elseif type == "3day"
        if date == Dates.today()
            date = date - Dates.Day(4) # FIXME: will 4 days always work, at any time of day?
        end
        # https://data.remss.com/amsr2/ocean/L3/v08.2/3day/2026/RSS_AMSR2_ocean_L3_3day_2026-08-20_v08.2.nc
        #?https://data.remss.com/amsr2/ocean/L3/v08.2/daily/2026/RSS_AMSR2_ocean_L3_daily_2026-08-21_v08.2.nc
        destfile = @sprintf(
            "RSS_AMSR2_ocean_L3_%s_%04d-%02d-%02d_v08.2.nc",
            type, year(date), month(date), day(date))
        url = @sprintf("%s/%s/%d/%s", server, type, year(date), destfile)
    elseif type == "monthly"
        # https://data.remss.com/amsr2/ocean/L3/v08.2/monthly/RSS_AMSR2_ocean_L3_monthly_2026-06_v08.2.nc
        if date == Dates.today()
            date = date - Dates.Month(2)
        end
        destfile = @sprintf(
            "RSS_AMSR2_ocean_L3_%s_%04d-%02d_v08.2.nc",
            type, year(date), month(date))
        url = @sprintf("%s/%s/%s", server, type, destfile)
    elseif type == "weekly"
        # https://data.remss.com/amsr2/ocean/L3/v08.2/weekly/RSS_AMSR2_ocean_L3_weekly_2026-08-08_v08.2.nc
        if date == Dates.today()
            # The weekly data files are timestamped on Sundays
            days_to_prior_sunday = mod(Dates.dayofweek(date), 7)  # 0 if Sunday, 1..6 otherwise
            date = date - Day(days_to_prior_sunday) - Dates.Week(2)
        end
        destfile = @sprintf(
            "RSS_AMSR2_ocean_L3_%s_%04d-%02d-%02d_v08.2.nc",
            type, year(date), month(date), day(date))
        url = @sprintf("%s/%s/%s", server, type, destfile)
    else
        error("type must be one of: \"3day\", \"daily\", \"monthly\" or \"weekly\" but it is \"$(type)\"")
    end
    destpath = expanduser(joinpath(destdir, destfile))
    oad(debug, "    destpath: '$destpath'")
    oad(debug, "    url: '$url'")
    if !isfile(destpath)
        oad(debug, "    downloading $url")
        try
            Downloads.download(url, destpath)
        catch err
            # remove possibly created empty file
            isfile(destpath) && rm(destpath; force=true)
            # translate HTTP or network errors into a clearer message
            throw(ErrorException("Failed to download $url: $err"))
        end
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
 
Plot a heatmap of a field in an [`Amsr`](@ref) object.  By default, SST is shown using the `:turbo`
colorscheme, and the view is of the whole earth. For "daily" datasets (see the `type`
argument of the [`get_amsr`](@ref) function), the ascending and descending swaths are averaged.

# Arguments

- `amsr`: An [`Amsr`](@ref) object, as read by [`read_amsr`](@ref).

# Keywords

- `xlims`: a tuple giving the range of longitude to be shown.  This is based on
  the 0 to 360 notation, since that is how AMSR data are stored.

- `ylims`: a tuple giving the range of latitude to be shown. This is based on
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
    aspect_ratio = 1.0 / cos(pi * 0.5 * (ylims[1] + ylims[2]) / 180.0)
    p = heatmap(longitude, latitude, amsr.data,
        xlims=xlims, ylims=ylims, aspect_ratio=aspect_ratio,
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
        elseif isa(draw_contours, AbstractVector) && eltype(draw_contours) <: Real
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
    lon = a.metadata["longitude"]
    lat = a.metadata["latitude"]
    lonOK = (lonlims[1] .<= lon) .& (lon .<= lonlims[2])
    latOK = (latlims[1] .<= lat) .& (lat .<= latlims[2])
    if count(lonOK) == 0 || count(latOK) == 0
        throw(ArgumentError("No data exist between stated longitude/latitude limits"))
    end
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

