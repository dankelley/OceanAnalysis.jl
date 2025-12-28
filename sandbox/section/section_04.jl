using OceanAnalysis, Plots, Statistics
url = "https://cchdo.ucsd.edu/data/11852/ar07_74JC20140606_ct1.zip";
dir = get_section(url);
s = read_section(dir);
look = 101:109
look = 101:106
look = 104:109
s.data = s.data[look];
#plot_section(s, xlim=[-49, -36], ylim=[57.5, 62.5])
#scale_bar(200, :right, :top)
# Must grid to show cross-section plots
sg = grid_section(s);
sg["depth"];
sg["latitude"];
sg.data[1]["z"];
sg.data[1]["pressure"];
#section_is_gridded(sg)
levels = 30.00:0.1:36.00
plot_section(sg, "salinity"; ylim=(0, 1000), framestyle=:box, yflip=true, color=:black, linewidth=1.0, levels=levels, cbar=false, clabels=true)

levels = range(-5.0, 10.0, step=0.5)

pl=plot_section(sg, "temperature"; ylim=(0, 1000), color=:black, grid=false,
linewidth=1.0, levels=levels, cbar=false, clabels=true, tickdirection=:out, framestyle=:semi)
xlim,ylim = xlims(), ylims();
plot!(pl, sg["latitude"], sg["depth"], color=:tan, lw=2, legend=false, xlim=xlim, ylim=ylim)
for lat in sg["latitude"]
    plot!(pl, [lat,lat], [1000.,0.], lw=3, seriestype=:line, color=:red, legend=false)
end
pl

savefig("section_04.pdf")
