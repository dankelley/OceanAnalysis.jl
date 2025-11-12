using ZipFile, ProgressMeter

"""
    Download a remote file or identify an existing version if it is young

The contents of `url` are downloaded and stored as `file`, but only if either
`file` does not exist locally or its age is less than `age` days.
"""
function get_file(url::String="", file::String="", age::Real=1.0; debug::Int64=0)
    oad(debug, "get_file START")
    if length(url) < 1 || length(file) < 1
        error("Must give 'url' and 'file'")
    end
    file = expanduser(file)
    oad(debug, "    url: \"", url, "\"")
    oad(debug, "    file: \"", file, "\"")
    if isfile(file)
        file_age = convert(Dates.Millisecond, now(UTC) - Dates.unix2datetime(mtime(file))) / Dates.Millisecond(1000) / 86400.0
    else
        file_age = 1e8 # so old that it will be forced to download
    end
    if file_age > age
        oad(debug, "    downloading file, since the existing version is ",
            round(file_age, digits=4), " days old, exceeding threshold of ", age, " days")
        Downloads.download(url, file)
    else
        oad(debug, "    using cached file, since its age ", round(file_age, digits=4), " is under ", age, " days")
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

