"""
    read_amsr(filename::String, field::String="SST", debug=0)

Reads a NetCDF file containing AMSR data.

This returns a value of the [`Amsr`](@ref) type, with `metadata` containing
the `filename` along with vectors holding the `longitude` and `latitude` of
the grid.  The `data` field holds a matrix of the data element with the
indicated `name` (e.g. `name="SST"` for sea-surface temperature).

# Arguments

- `filename` a string indicating the location of the local file.

- `field` a string used to identify the data field to be extracted.  If
`field="?"` then `read_amsr` returns a vector of strings containing extractable
data.  Otherwise, if `field` names one of those items, then `read_amsr` returns
that dataset.

# Examples

```juliadoc
using OceanAnalysis, Plots
f = "~/data/amsr/RSS_AMSR2_ocean_L3_3day_2025-09-07_v08.2.nc";
d = read_amsr(f, "SST");
longitude = d.metadata["longitude"];
latitude = d.metadata["latitude"];
SST = d.data;
heatmap(longitude, latitude, SST, framestyle=:box, aspect_ratio=:equal,
    xlims=(0, 360), ylims=(-90, 90), dpi=300, size=(800, 400),
    title=f * ": SST", titlefontsize=9)
```
"""
function read_amsr(filename::String, field::String="SST", debug=0)
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

Download Advanced Microwave Scanning Radiometer data.

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

- `date` a Date object specifying the requested measurement time. This defaults
to 4 days prior to the current date.

# Keywords

- `destdir`: Path to the destination directory. The author usually sets `destdir="~/data/amsr"`, so that the file will be in a central location for use by other analysis procedures.

- `server`: The base of the server location. The default value ought to be used unless the data provider changes their web scheme, although the likelihood of the query working in such a case is slim, since changes tend to be sweeping.

- `type`: The type of data requested. At the moment, the only choice is `"3day"` (the default), for a composite covering 3 days of observation, which removes most viewing-path and cloud blanks. If there is sufficient need, other types may be added, from the list: `"daily"` for a daily reading, `"weekly"` for a composite covering a week, and `"monthly"` for a composite covering a month.  In the `"daily"` case, the data arrays are 3D, with the third dimension representing ascending and descending traces, but in all the other cases, the arrays are 2D.

- `debug`: An indication of whether to print information during processing. The default value of 0 means to work quietly, and any larger integer indicates to print some information.

# Return

`get_amsr_file` returns a string that is the full pathname of the downloaded file.
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
