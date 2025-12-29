# Animate section stations by time of sampling
# using Pkg ; Pkg.add(url="https://github.com/dankelley/OceanAnalysis.jl")
using OceanAnalysis, Plots, Printf
url = "https://cchdo.ucsd.edu/data/11852/ar07_74JC20140606_ct1.zip";
dir = get_section(url);
s = read_section(dir);
lon = s["longitude"];
lat = s["latitude"];
time = s["time"];
station = s["station"];
anim = @animate for i in 1:length(lon)
    plot_section(s, color=:gray, markersize=1.5, size=(600, 400))
    xlim, ylim = xlims(), ylims()
    scatter!([lon[1:i]], [lat[1:i]], markersize=3.0, color=:red)
    label = @sprintf("%s stn %s at %s", dir, station[i], time[i])
    annotate!(0.5 * (xlim[1] + xlim[2]), ylim[2] + 0.5,
        text(label, :black, :center, 9))
end
mp4(anim, "section_animate.mp4");
