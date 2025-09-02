# %%
using OceanAnalysis
SP = [34., NaN, 34.2, 34.3]
p = [10.0, 11.0, NaN, 13.0]
lon = repeat([-30.], 4)
lat = repeat([30.], 4)
SA.(SP, p, lon, lat)
