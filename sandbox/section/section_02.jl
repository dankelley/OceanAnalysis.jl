using OceanAnalysis

function OAD(debug, msg)
    if debug > 0
        println(msg)
    end
end

mutable struct Section_TEST <: OA
    metadata::Dict{String,Any}
    data::Vector{Ctd}
end

function as_section_TEST(ctds; name::String="", source::String="", debug=0)
    OAD(debug, "as_section() START")
    nctds = length(ctds)
    nctds > 0 || error("  as_section() provided with zero-length first argument")
    metadata = Dict()
    metadata["name"] = name
    metadata["source"] = source
    data = Vector{Ctd}(undef, nctds)
    for i in 1:nctds
        OAD(debug, "  save $i-th entry") # FIXME: maybe use a progress bar instead
        data[i] = ctds[i]
    end
    OAD(debug, "END as_section()")
    Section_TEST(metadata, data)
end

# Create fake data (with S and T varying between stations)
f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv");
a = read_ctd_cnv(f, add_teos=false);
b = read_ctd_cnv(f, add_teos=false);
c = read_ctd_cnv(f, add_teos=false);
b.data.salinity = 1.0 .+ b.data.salinity;
b.data.temperature = 1.0 .+ b.data.temperature;
c.data.salinity = 2.0 .+ c.data.salinity;
c.data.temperature = 1.0 .+ c.data.temperature;

# next takes 0.02 seconds
@time section = as_section_TEST((a, b, c), name="sample section");

println("Section \""* section.metadata["name"] * "\" has entries with data starting:")
for i in 1:length(section.data)
    println(first(section.data[i].data, 2))
end
