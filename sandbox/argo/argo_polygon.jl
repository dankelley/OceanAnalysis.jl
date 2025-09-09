# %%
using OceanAnalysis
if !@isdefined index
    index = read_argo_index("~/data/argo/ss/ar_index_global_prof.txt.gz")
end
println(names(index))

# %%
# Define a polygon as a list of coordinate tuples (x, y).
# The polygon should be closed (the last point is the same as the first)
# to make its intent clear, though the function handles it.
polygon = [(0.0, 0.0), (5.0, 0.0), (5.0, 5.0), (0.0, 5.0), (0.0, 0.0)]

# Define the points to check
#. point_inside = (2.0, 3.0)
#. point_outside = (6.0, 6.0)
#. point_on_boundary = (5.0, 2.0)
#. 
# The inpolygon function returns an integer result:
#  - 1 if the point is strictly inside
#  - -1 if the point is strictly outside
#  - 0 if the point is on the boundary
#. inside_result = inpolygon(point_inside, polygon)
#. outside_result = inpolygon(point_outside, polygon)
#. on_boundary_result = inpolygon(point_on_boundary, polygon)
#. 
#. println("Point $point_inside: $inside_result")
#. println("Point $point_outside: $outside_result")
#. println("Point $point_on_boundary: $on_boundary_result")

# To get a simple boolean result (true/false) for 'inside', you can check for equality with 1.
#. using PolygonOps
#. is_inside = inpolygon(point_inside, polygon) == 1
#. println("Is $point_inside inside? $is_inside")

# %%
using PolygonOps, Distributions, Plots
n = 100000
x = rand(Uniform(-1.0, 6.0), n);
y = rand(Uniform(-1.0, 6.0), n);
plot(x, y, seriestype=:scatter, color=:lightgray, markerstrokecolor=:lightgray, markersize=1, legend=false)
@time inside = filter(i -> inpolygon((x[i], y[i]), polygon) == 1, 1:n);
scatter!(x[inside], y[inside], markersize=1, color=:black)
