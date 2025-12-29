using OceanAnalysis
url_exchange = "https://cchdo.ucsd.edu/data/41926/90CT40_1_ct1.zip"
url_woce = "https://cchdo.ucsd.edu/data/41925/90CT40_1_ct.zip"
dir = get_section(url_woce)
s = read_section(dir)
plot_section(s)

