using HTTP, JSON
import Base.parse

"""
    get_erddap_index(server::String="https://cioosatlantic.ca/",
        item::String="bio_maritimes_glider_SkyeSEA021_20230411";
        debug::Integer=0)

Find URLs listed on an ERDDAP website. By default, the URL of the website is
constructed as `"\$(server)/erddap/files/\$(item)/.json"`. However, if `server`
ends in the string `"/.json"`, then the URL is simply set to `server`,
regardless of the value of `item`. The second form is intended for cases in
which the first form cannot be reached, perhaps because the directory
structure has changed.

The default arguments will yield an index of a particular glider deployed by
the Bedford Institute of Oceanography.

# Return

A Vector of String values that specify URLs for the files in the index.

# Arguments

- `server` a String specifying the server to be indexed; see above.

- `item` an optional String specifying the item; see above.

# Keywords

- `debug`: An indication of whether to print information during processing. The
  default value of 0 means to work quietly, and any larger integer indicates to
  print some information.

# Examples

```julia
using OceanAnalysis
urls = get_erddap_index("https://cioosatlantic.ca",
    "bio_maritimes_glider_SkyeSEA021_20230411");
# Download first file, unless it exists and is < 10 days old.
get_file(urls[1], destdir=".", age=10)
```

"""
function get_erddap_index(server::String="https://cioosatlantic.ca/",
    item::String="bio_maritimes_glider_SkyeSEA021_20230411"; debug::Integer=0)
    oad(debug, "get_erddap_index() START")
    oad(debug, "  server: $server")
    oad(debug, "  item: $item")
    if endswith(server, "/.json")
        url = server
    else
        url = "$(server)/erddap/files/$(item)/.json"
    end
    oad(debug, "  url: $url")
    url_without_dot_json = replace(url, "/.json" => "")
    oad(debug, "  url_without_dot_json: $url_without_dot_json")
    response = HTTP.get(url)
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
end
