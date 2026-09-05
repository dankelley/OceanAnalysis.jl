using NCDatasets
using Dates
using DataFrames
using Downloads
using GibbsSeaWater
using GMT: gmtread
using Interpolations
using Makie: Figure, Axis, heatmap!, contour!, poly!, Colorbar, AxisAspect, Point2f, limits!
using Plots
using Printf
using CSV
using Dierckx
using Statistics
using StatsBase
using TiffImages

# Types
export OA # the base from which the folowing inherit
export Adp
export Amsr
export Argo
export Ctd
export Coastline
export Dem
export Echosounder
export Glider
export Nonna
export Section
export Topography

