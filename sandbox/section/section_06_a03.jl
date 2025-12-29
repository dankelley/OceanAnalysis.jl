using OceanAnalysis
#url = "https://cchdo.ucsd.edu/data/41926/90CT40_1_ct1.zip" # exchange format
url = "https://cchdo.ucsd.edu/data/41925/90CT40_1_ct.zip" # WOCE format (FAILS to read)
dir = get_section(url)
s = read_section(dir, debug=1);
plot_section(s)

