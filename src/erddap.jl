using HTTP, JSON
import Base.parse

"""
    get_erddap_index(server::String="https://cioosatlantic.ca/",
        dir::String="bio_maritimes_glider_SkyeSEA021_20230411";
        debug::Integer=0)

Find URLs listed on an ERDDAP website. There are three ways to do this.

1. If both `server` and `dri` are given (as in the default), then URL of the
   website is constructed as `"\$(server)/erddap/files/\$(dir)/.json"`.

2. If `server` ends in the string `"/.json"`, then the URL is simply set to
   `server`, regardless of the value of `dir`. This offers the most
   flexibility to the user, at the expense of demanding some understanding of
   the URL structure.

3. If `dir` is a zero-length string, then an overall index of the ERDDAP is
   returned. Items that end with `"/"` are directories, so a call in this
   form can be a first step in exploring what data the ERDAPP provides.

# Return

A Vector of String values that specify URLs for the files in the index.

# Arguments

- `server` a String specifying the server to be indexed; see above.

- `dir` an optional String specifying the directory of interest on the server;
  see above.

# Keywords

- `debug`: An indication of whether to print information during processing. The
  default value of 0 means to work quietly, and any larger integer indicates to
  print some information.

# Examples

```julia
using OceanAnalysis
urls = get_erddap_index("https://cioosatlantic.ca",
    "bio_maritimes_glider_SkyeSEA021_20230411");

# Isolate files from date 2023-05-01
look = occursin.("20230501", urls)
urls_focus = urls[look]
println(urls_focus)

# Download the first file in the list
get_file(urls_focus[1], destdir=".", age=10)

# Get directory names, which are distinguished from file names
# by a trailing "/" character.
dirs = get_erddap_index("https://cioosatlantic.ca", "")
dirs = dirs[endswith.(dirs, "/")]
dirs = sort([split(dir, "/")[end-1] for dir in dirs])
dirs
```

"""
function get_erddap_index(server::String="https://cioosatlantic.ca/",
    dir::String="bio_maritimes_glider_SkyeSEA021_20230411"; debug::Integer=0)
    oad(debug, "get_erddap_index() START")
    oad(debug, "  server: \"$server\"")
    oad(debug, "  dir: \"$dir\"")
    if endswith(server, "/.json")
        url = server
    else
        url = "$(server)/erddap/files/$(dir)/.json"
    end
    oad(debug, "  url: \"$url\"")
    url_without_dot_json = replace(url, "/.json" => "")
    oad(debug, "  url_without_dot_json: \"$url_without_dot_json\"")
    response = HTTP.get(url; status_exception=false)
    if response.status == 200
        data = JSON.parse(String(response.body))
        file_rows = data["table"]["rows"]
        n = length(file_rows)
        files = Vector{String}(undef, n)
        for i in 1:n
            files[i] = file_rows[i][1] # 1=name, 2=modified_time, 3=size
        end
        urls = (url_without_dot_json * "/") .* files
        oad(debug, "END get_erddap_index()")
        return urls
    else
        error("cannot access erddap at $url")
    end
end
export get_erddap_index
