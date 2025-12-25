using ZipFile, ProgressMeter

"""
    get_file(url::String=""; destdir::String=".", age::Real=1.0, debug::Int64=0)

Download/cache a remote file

The `url` is a remote source for a file to be downloaded. If no file
of that name exists in the destination directory, `destdir`,
then the file is downloaded and its name is returned. However,
if such a file already exists, and if its age is under `age`
days, then the file is assumed to be up-to-date and is not
downloaded.  Some processing steps are printed if `debug>0`.
"""
function get_file(url::String=""; destdir::String=".", age::Real=1.0, debug::Int64=0)
    oad(debug, "get_file START")
    length(url) > 0 || error("Must give 'url")
    file = replace(url, r".*/" => "")
    file = expanduser(joinpath(destdir, file))
    oad(debug, "    url: \"", url, "\"")
    oad(debug, "    file: \"", file, "\"")
    if isfile(file)
        file_age = convert(Dates.Millisecond, now(UTC) - Dates.unix2datetime(mtime(file))) / Dates.Millisecond(1000) / 86400.0
        if file_age > age
            oad(debug, "    downloading file, since the existing version is ",
                round(file_age, digits=4), " days old, exceeding threshold of ", age, " days")
            Downloads.download(url, file)
        else
            oad(debug, "    using the cached version of the file, since it is under ", age, " days old")
        end
    else
        oad(debug, "    downloading file, since it is not cached in the '$destdir' directory")
        Downloads.download(url, file)
    end
    oad(debug, "END get_file")
    file
end


"""
    get_section(url::String; destdir=".", debug::Bool=false)

Download a zipfile from `url` and expand its contents into files within a
destination directory inferred from the URL or as defined by `destdir`, if the
latter is not missing.

The work starts by downloading a zipfile to the local directory, if
it is not already present.  Then a directory name is constructed
based on `url` and the value of `destdir`. If no such
directory exists, it is created. Then the zipfile is expanded,
storing the contents in this new directory.

The return value is the name of the new directory.

Setting `debug=1` will cause the printing of some of the processing
steps.

# Examples

```juliadoc
using OceanAnalysis
# Saves files into a local directory called 'ar07_74JC20140606'.
url = "https://cchdo.ucsd.edu/data/11852/ar07_74JC20140606_ct1.zip"
sdir = get_section(url)
println("Downloaded ", length(readdir(sdir)), " files to '", sdir, "'")
```
"""
function get_section(url::String; destdir=".", debug::Int64=0)
    # FIXME: maybe an argument to reset for a fresh download+extraction
    oad(debug, "get_section() START")
    destdir = joinpath(destdir, replace(url, r".*/(.*)_ct1.zip" => s"\1"))
    zip = replace(url, r".*/" => "")
    if isfile(zip)
        oad(debug, "    using existing zipfile ", zip)
    else
        oad(debug, "    downloading zipfile from ", url)
        Downloads.download(url, zip)
    end
    archive = ZipFile.Reader(zip)
    if isdir(destdir)
        oad(debug, "    using existing directory ", destdir)
    else
        oad(debug, "    creating directory ", destdir)
        mkpath(destdir)
    end
    oad(debug, "    saving ", length(archive.files), " files in ", destdir)
    # show a progress bar, but typically the work completes before it even appears.
    progress = Progress(length(archive.files), enabled=debug == 1 ? true : false)
    for file in archive.files
        write(joinpath(destdir, file.name), read(file, String))
        next!(progress)
    end
    close(archive)
    oad(debug, "END get_section()")
    return (destdir)
end

"""
    get_element(x::OA, element::String; debug)

Get an element from an object.

If `x.metadata` holds an item of the given name, return that item. If not,
and if `x.data` holds such an item, return that item.

If `x` is a [`Ctd`](@ref) object, some computed things may be returned. These
are `N2`, `SA`, `CT`, `sigma0` and `spiciness0`.

If `x` is a [`Section`](@ref) object, then `get_element` can return any
item from the `metadata` of the constituent [`Ctd`](@ref)
objects that are stored in `x.data`.  For an example,
see the documentation for [`read_section`](@ref).
"""
function get_element(x::OA, element::String; debug::Int64=0)
    oad(debug, "get_element([OA object], name=$element) START")
    # If element is in metadata, return that
    if element in keys(x.metadata)
        return x.metadata[element]
    end
    # If element is in data (and if data is a DataFrame), return that
    if isa(x.data, DataFrame) && element in names(x.data)
        return copy(x.data[:, element])
    end
    # If this is a Ctd object, we can return certain computed things
    if typeof(x) == Ctd
        if element == "N2"
            return copy(N2(x))
        end
        SP = x.data.salinity
        T = x.data.temperature
        p = x.data.pressure
        longitude = x.metadata["longitude"]
        latitude = x.metadata["latitude"]
        local SA = gsw_sa_from_sp.(SP, p, longitude, latitude) |> fix_gsw_bad_code!
        if element == "SA"
            return copy(SA)
        end
        local CT = gsw_ct_from_t.(SA, T, p) |> fix_gsw_bad_code!
        if element == "CT"
            return copy(CT)
        end
        if element == "sigma0"
            return copy(gsw_sigma0.(SA, CT)) |> fix_gsw_bad_code!
        end
        if element == "spiciness0"
            return copy(gsw_spiciness0.(SA, CT)) |> fix_gsw_bad_code!
        end
    elseif typeof(x) == Section
        # assume all CTDs have same metadata names
        if element in keys(x.data[1].metadata)
            return copy(map(ctd -> get_element(ctd, element), x.data))
        end
    end
    # The item is not handled, so return an empty result
    return Nothing
end
