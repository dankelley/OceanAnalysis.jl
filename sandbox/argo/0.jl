using OceanAnalysis
sample_file = "aoml/1900185/profiles/D1900185_088.nc"
get_argo("~/data/argo/ss", sample_file, 0.0, debug=1)
get_argo("~/data/argo/ss", sample_file, debug=1)
