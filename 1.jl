using OceanAnalysis, Plots
file = "/Users/kelley/Dropbox/data/archive/sleiwex/2008/fielddata/2008-07-01/Merlu/Biosonics/20080701_163942.dt4"
adp = read_echosounder(file; debug=1);
