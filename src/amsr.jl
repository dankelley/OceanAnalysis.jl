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

- `field`: a string used to identify the data field to be extracted.  If `field="?"` then `read_amsr` returns a vector of strings containing extractable data.  Otherwise, if `field` names one of those items, then `read_amsr` returns that dataset.
# Keywords

- `debug`: An indication of whether to print information during processing. The default value of 0 means to work quietly, and any larger integer indicates to print some information.

# Examples

```juliadoc
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
        oad(debug, "    about to read SST.")
        if field == "?"
            return keys(nc)
        else
            metadata = Dict()
            metadata["filename"] = filename
            metadata["longitude"] = copy(nc["lon"])
            metadata["latitude"] = copy(nc["lat"])
            data = copy((Float64.(replace(nc[field], missing => NaN)))')
            oad(debug, "END read_amsr()")
            return Amsr(metadata, data)
        end
    end
end



"""
    get_amsr_file(date::Date=Dates.today() - Day(4); type::String="3day",
        destdir::String=".", server::String="https://data.remss.com/amsr2/ocean/L3/v08.2",
        debug::Integer=0)

Download a Advanced Microwave Scanning Radiometer data file.

This works by constructing a filename to be downloaded. If that file does not
exist in `destdir`, then it is downloaded from the server, and `get_amsr_file`
returns the full path to that existing file. Otherwise, the file is downloaded,
and the return value is the path to the resultant local file.

For example, if this function is called on 2025-09-27 with no arguments
specified, an attempt will be made to download a file named
`"./RSS_AMSR2_ocean_L3_3day_2025-09-23_v08.2.nc"` from the server
`https://data.remss.com/amsr2/ocean/L3/v08.2/3day/2023/".

See [`read_amsr`](@ref) for how to deal with the files downloaded
by `get_amsr_file`.

# Arguments

- `date` a Date object specifying the requested measurement time. This defaults to 4 days prior to the current date.

# Keywords

- `destdir`: Path to the destination directory. The author usually sets `destdir="~/data/amsr"`, so that the file will be in a central location for use by other analysis procedures.

- `server`: The base of the server location. The default value ought to be used unless the data provider changes their web scheme, although the likelihood of the query working in such a case is slim, since changes tend to be sweeping.

- `type`: The type of data requested. At the moment, the only choice is `"3day"` (the default), for a composite covering 3 days of observation, which removes most viewing-path and cloud blanks. If there is sufficient need, other types may be added, from the list: `"daily"` for a daily reading, `"weekly"` for a composite covering a week, and `"monthly"` for a composite covering a month.  In the `"daily"` case, the data arrays are 3D, with the third dimension representing ascending and descending traces, but in all the other cases, the arrays are 2D.

- `debug`: An indication of whether to print information during processing. The default value of 0 means to work quietly, and any larger integer indicates to print some information.

# Return

`get_amsr_file` returns a string that is the full pathname of the downloaded file, which may be supplied as
the first argument to a call to [`read_amsr`](@ref).
"""
function get_amsr_file(date::Date=Dates.today() - Day(4); type::String="3day",
    destdir::String=".", server::String="https://data.remss.com/amsr2/ocean/L3/v08.2",
    debug::Integer=0)
    oad(debug, "get_amsr_file START")
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
    oad(debug, "END get_amsr_file")
    destpath
end
