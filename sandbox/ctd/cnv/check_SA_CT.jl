using OceanAnalysis, DataFrames, Printf
# Alter Base.show so we see 15 digits
Base.show(io::IO, t::Float64) = @printf io "%.15f" t
f = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "ctd.cnv")
ctd = read_ctd_cnv(f)
df = DataFrame(SA=ctd.data.SA, CT=ctd.data.CT)
println(df)
