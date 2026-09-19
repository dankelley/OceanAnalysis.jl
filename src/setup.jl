using NCDatasets
using Dates
using DataFrames
using Downloads
using GibbsSeaWater
using GMT: gmtread
using Interpolations
#using Makie: Axis, AxisAspect, Colorbar, DataAspect, Figure, FigureAxisPlot, Point2f, Polygon, RGBAf, contour!, contourf!, current_axis, heatmap!, limits!, lines!, poly!, scatter!, scatterlines!, text!, to_colormap
import Makie
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

