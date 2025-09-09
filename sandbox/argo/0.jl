# %%
using OceanAnalysis
#index_file = download_argo_index("~/data/argo/ss")
#index = read_argo_index(index_file)
sample_file = "aoml/1900185/profiles/D1900185_088.nc" # index[10000, "file"] # "aoml/1900185/profiles/D1900185_088.nc"
download_argo_file("~/data/argo/ss", sample_file, 0.0, debug=1)
download_argo_file("~/data/argo/ss", sample_file, debug=1)
