# Demonstrate that the GSW julia code does not yield the SA test results
# stated at https://www.teos-10.org/pubs/gsw/html/gsw_SA_from_SP.html
using GibbsSeaWater, DataFrames, PrettyTables
SP = [34.5487; 34.7275; 34.8605; 34.6810; 34.5680; 34.5600]
p = [10.0; 50.0; 125.0; 250.0; 600.0; 1000.0]
long = 188
lat = 4
PrettyTable(gsw_sa_from_sp(SP[1], p[1], long, lat))

long = 188.0
lat = 4.0
official = [34.711778344814114; 34.891522618230098; 35.025544862476920; 34.847229026189588; 34.736628474576051; 34.732363065590846]
trial = gsw_sa_from_sp.(SP, p, long, lat)
diff = official - trial
rdiff = diff ./ official
println(DataFrame(official=official, trial=trial, diff=diff, rdiff=rdiff))
