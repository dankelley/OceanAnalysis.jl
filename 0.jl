# %%
function f(x, y)
    x + y
end
using OceanAnalysis, Test, DataFrames, GibbsSeaWater_jll
d = read_ctd_cnv("data/ctd.cnv")
#println(first(d.data, 3))
#println(first(SA(d), 3))
println("match? ", SA(d) == d.data.SA)

# %%
# Test at https://www.teos-10.org/pubs/gsw/html/gsw_SA_from_SP.html as of 2024-09-02
SP = [34.5487; 34.7275; 34.8605; 34.6810; 34.5680; 34.5600]
p = [10.0; 50.0; 125.0; 250.0; 600.0; 1000.0]
lat = 4.0
lon = 188.0
# expected value
A = [34.711778344814114; 34.891522618230098; 35.025544862476920; 34.847229026189588; 34.736628474576051; 34.732363065590846]
# this code
B = SA.(SP, p, lon, lat)
# GSW directly
C = gsw_sa_from_sp.(SP, p, lon, lat)

println(DataFrame(expect=A, B=B, C=C, AB=A - B, AC=A - C, BC=B - C))
@test A ≈ B atol = 1e-3
