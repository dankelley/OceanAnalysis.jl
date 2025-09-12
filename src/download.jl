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
