using OceanAnalysis
d = read_ctd_woce("/Users/kelley/git/OceanAnalysis.jl/data/ar07_74JC20140606_00234_00001_ct1.csv", debug=1)
for (key, value) in d.metadata
    println("metadata['$key']: $value")
end
plot_TS(d)

