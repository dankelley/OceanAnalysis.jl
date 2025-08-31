using OceanAnalysis
files = ["/Users/kelley/Dropbox/oce-working-notes/cnv/JR302_001_align_ctm.cnv";
    "/Users/kelley/Dropbox/oce-working-notes/cnv/first_CTD_cast.cnv"]
d = read_ctd_cnv(files[1], debug=1)
