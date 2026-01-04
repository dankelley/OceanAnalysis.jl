using Dates, Plots


function find_adp_rdi_ensembles(buf; debug::Int64=0)
    nbuf = length(buf)
    start = 1
    while true # Find first 7f 7f byte pair, in case file starts mid-ensemble
        if buf[start] == 0x7f & buf[start+1] == 0x7f
            break
        end
        start += 1
        if start >= nbuf - 1
            error("no 0x7f 0x74 in file $file")
        end
    end
    starts = Vector{Int64}()
    ensemble::Int64 = 0
    while true
        ensemble = ensemble + 1
        if start >= nbuf
            if debug > 0
                println("EOF encountered whilst attempting to read ensemble $ensemble")
            end
            break
        end
        # Do next manually, since (I think) Julia obeys OS endianness
        #> bytes_to_check = Int16(reinterpret(UInt16, buf[2:3])[1])
        local bytes_to_check = buf[start+2] + 256 * buf[start+3]
        #println("ensemble $ensemble, start $start, bytes_to_check $bytes_to_check")
        #local bytes_to_read = bytes_to_check - 4
        ntypes = buf[start+5]
        if ntypes < 1 | ntypes > 200
            error("something is wrong with ntypes (=$ntypes)")
        end
        local checksum::UInt16 = 0
        for i in range(start, length=bytes_to_check)
            checksum += buf[i] # relies on overflow wrapping around zero
        end
        local desired_checksum = buf[start+bytes_to_check] + 256 * buf[start+bytes_to_check+1]
        if checksum == desired_checksum
            push!(starts, start)
        else
            #println("  bad checksum=$checksum (desired_checksum=$desired_checksum)")
        end
        start += bytes_to_check + 2
    end
    starts
end

function read_adp_rdi_header(buf, start::Int64=1; debug::Int64=0)
    metadata = Dict()
    ntypes = Int(buf[start+5])
    metadata["ntypes"] = ntypes
    if ntypes < 1 | ntypes > 200
        error("something is wrong with ntypes (=$ntypes)")
    end
    # data_offset in 2-byte elements
    data_offsets = Vector{Int}(undef, ntypes)
    for i in 1:ntypes
        tmp = start + 4 + 2 * i
        data_offsets[i] = buf[tmp] + 256 * buf[tmp+1]
    end
    metadata["data_offsets"] = data_offsets
    # Now look past 'header' to 'fixed leader', but
    # just for things that will not change over the
    # course of sampling.
    start_fl = start + 5 + 2 * ntypes
    version_major = string(buf[start_fl+3])
    version_minor = string(buf[start_fl+4])
    metadata["version"] = version_major * "." * version_minor
    sys_config_LSB = reverse(digits(buf[start_fl+5], base=2, pad=8))
    sys_config_MSB = reverse(digits(buf[start_fl+6], base=2, pad=8))
    # frequency in last 3 bits of LSB
    if sys_config_LSB[6:8] == [0; 0; 0]
        frequency = 75
    elseif sys_config_LSB[6:8] == [0; 0; 1]
        frequency = 150
    elseif sys_config_LSB[6:8] == [0; 1; 1]
        frequency = 300
    elseif sys_config_LSB[6:8] == [1; 0; 0]
        frequency = 1200
    elseif sys_config_LSB[6:8] == [1; 0; 1]
        frequency = 2400
    else
        frequency = NaN
    end
    metadata["frequency"] = frequency
    metadata["direction"] = sys_config_LSB[1] == 0 ? "down" : "up"
    metadata["convex"] = sys_config_LSB[5] == 1
    if sys_config_MSB[7:8] == [0; 0]
        beam_angle = 15.0
    elseif sys_config_MSB[7:8] == [0; 1]
        beam_angle = 20.0
    elseif sys_config_MSB[7:8] == [1; 0]
        beam_angle = 30.0
    else
        beam_angle = NaN
    end
    metadata["beam_angle"] = beam_angle
    if sys_config_MSB[1:4] == [0, 1, 0, 0]
        metadata["beam_configuration"] = :four_beam_janus
    elseif sys_config_MSB[1:4] == [0, 1, 0, 1]
        metadata["beam_configuration"] = :five_beam_janus_demod
    elseif sys_config_MSB[1:4] == [1, 1, 1, 1]
        metadata["beam_configuration"] = :five_beam_janus_two_demod # spelling?
    else
        metadata["beam_configuration"] = :unknown
    end
    # compute transformation matrix (formula borrowed from R/oce)
    C = metadata["convex"] ? 1.0 : -1.0
    A = 1.0 / (2.0 * sin(metadata["beam_angle"] * pi / 180.0))
    B = 1.0 / (4.0 * cos(metadata["beam_angle"] * pi / 180.0))
    D = A / sqrt(2.0)
    metadata["transformation_matrix"] = [
        C*A -C*A 0.0 0.0;
        0.0 0.0 -C*A C*A;
        B B B B;
        D D -D -D]
    #println("sys_config_LSB $sys_config_LSB")
    #println("sys_config_MSB $sys_config_MSB")
    nbeams = Int(buf[start_fl+9])
    metadata["nbeams"] = nbeams
    ncells = Int(buf[start_fl+10])
    metadata["ncells"] = ncells
    depth_cell_length = 0.01 * (buf[start_fl+13] + 256 * buf[start_fl+14])
    metadata["depth_cell_length"] = depth_cell_length
    # Coordinate system
    cs_bits = reverse(digits(buf[start_fl+26], base=2, pad=8))
    coordinate_system = :unknown
    if cs_bits[4] == 0 && cs_bits[5] == 0
        coordinate_system = :beam
    elseif cs_bits[4] == 0 && cs_bits[5] == 1
        coordinate_system = :instrument
    elseif cs_bits[4] == 1 && cs_bits[5] == 0
        coordinate_system = :ship
    elseif cs_bits[4] == 1 && cs_bits[5] == 1
        coordinate_system = :earth
    end
    metadata["coordinate_system"] = coordinate_system
    # cell geometry
    bin1_distance = 0.01 * buf[start_fl+33] + 256 * buf[start_fl+34]
    metadata["bin1_distance"] = bin1_distance
    metadata["distance"] = range(bin1_distance, step=depth_cell_length, length=ncells)
    metadata
end


# R oce::read_adp() handles the following (or at least has intentions to do so)
#   0x00 0x01 velocity
#   0x00 0x02 correlation
#   0x00 0x03 echo_intensity
#   0x00 0x04 percent_good
#   0x00 0x06 bottom_track
#   0x00 0x0a sentinel_vertical_beam_velocity
#   0x00 0x0b sentinel_vertical_beam_correlation
#   0x00 0x0c sentinel_vertical_beam_amplitude
#   0x00 0x0d sentinel_vertical_beam_percent_good
#   0x00 0x20 VMDASS
#   0x00 0x30 binary_fixed_attitude_header
#   0x00 0x32 sentinel_transformation_matrix
#   0x00 0x0a sentinel_data
#   0x00 0x0b sentinel_correlation
#   0x00 0x0c sentinel_amplitude
#   0x00 0x0d sentinel_percent_good
#   0x80 0x00 variable_leader
"""
    read_adcp(file::String, ensembles::Union{Int64,Vector{Int64}}=0; debug::Int64=0)

Read an acoustic-Doppler profiler file that is in RDI format.

At present, only 4 data items can be read: `:velocity` (with byte code 0x00
0x01), `:correlation_magnitude` (0x00 0x02), `:echo_intensity`  (0x00 0x03) and
`:percent_good` (0x00 0x04). More types may be added later, as needs arise.
(NB. the `oce::read_adp()` R code handles 18 types.)

# Examples

```juliadoc
using OceanAnalysis, Plots
file = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "adp_rdi.000");
adp = read_adp_rdi(file);
heatmap(adp["velocity"][1, :, :], c=cgrad(:RdBu, rev=true))
plot(adp["time"], adp["heading"],
    ylab="Heading", label=false, framestyle=:box)
heatmap(adp["time"], adp["distance"], adp["velocity"][:,:,1],
    size=(800,600), ylab="Distance [m]", c=:RdBu)
```

# References
1. Teledyne RD Instruments. “Workhorse Commands and Output Data Format.” 2010.
"""
function read_adp_rdi(file::String, ensembles::Union{Int64,Vector{Int64}}=0; debug::Int64=0)
    oad(debug, "read_adp_rdi() START")
    oad(debug, "  ensembles: $ensembles (FIXME: use this argument)")
    function two_byte_unsigned(i)
        # Skip reinterpret() to avoid issues of endianness
        #reinterpret(UInt16, [buf[i], buf[i+1]])
        UInt16(buf[i+1]) << 8 | UInt16(buf[i])
    end
    function two_byte_signed(i)
        # Skip reinterpret() to avoid issues of endianness
        #reinterpret(Int16, [buf[i], buf[i+1]])
        signed(UInt16(buf[i+1]) << 8 | UInt16(buf[i]))
    end
    buf = read(file)
    # H_ holds pointers to the starts of ensembles.
    oad(debug, "  About to determine ensemble starting indices")
    H_ = find_adp_rdi_ensembles(buf)
    oad(debug, "  About to read header information in first ensemble")
    metadata = read_adp_rdi_header(buf, H_[1])
    metadata["file"] = file
    data = Dict()
    metadata["nensembles"] = length(H_)
    # FL_ holds pointers to the starts of fixed-length headers (See Figure 8 of [1])
    FL_ = H_ .+ 6 .+ 2 * metadata["ntypes"]
    0 == buf[FL_[1]] || stop("problem @ FL_[1]")
    0 == buf[FL_[1]+1] || stop("problem @ FL_[1] + 2")
    # VL_ holds pointers to the starts of variable-length headers
    VL_ = FL_ .+ 59 # (see Figure 8 of [1])
    # D_ holds pointers to the starts of data sections
    D_ = VL_ .+ 65 # (see Figure 8 of [1])
    0x80 == buf[VL_[1]] || error("problem w/ VL_starts[1]")
    0x00 == buf[VL_[1]+1]
    oad(debug, "  inferring time-series information")
    data["ensemble"] = buf[VL_.+2] + 245 * buf[VL_.+3]
    year = 2000 .+ buf[VL_.+4]
    month = Int.(buf[VL_.+5])
    day = Int.(buf[VL_.+6])
    hour = Int.(buf[VL_.+7])
    minute = Int.(buf[VL_.+8])
    second = Int.(buf[VL_.+9])
    data["time"] = DateTime.(year, month, day, hour, minute, second)
    # sound_speed (RDI p139 says bytes 15,16 so use 14,15 here);
    data["sound_speed"] = Float64.(two_byte_signed.(VL_ .+ 14))
    # heading RDI p139 says bytes 19,20 -- use 18,19 here
    data["heading"] = 0.01 * two_byte_signed.(VL_ .+ 18)
    # pitch RDI p139 says bytes 21,22 -- use 20,21 here
    data["pitch"] = 0.01 * two_byte_signed.(VL_ .+ 20)
    # roll RDI p139 says bytes 23,24 -- use 22,23 here
    data["roll"] = 0.01 * two_byte_signed.(VL_ .+ 22)
    codes = Array{UInt8,2}(undef, metadata["ntypes"], 2)
    oad(debug, "  determining data types")
    have_data = Symbol[]
    for t in 1:metadata["ntypes"]
        codes[t, 1] = buf[metadata["data_offsets"][t].+1]
        codes[t, 2] = buf[metadata["data_offsets"][t].+2]
        if codes[t, :] == [0x00, 0x01]
            push!(have_data, :velocity)
        end
        if codes[t, :] == [0x00, 0x02]
            push!(have_data, :correlation_magnitude)
        end
        if codes[t, :] == [0x00, 0x03]
            push!(have_data, :echo_intensity)
        end
        if codes[t, :] == [0x00, 0x04]
            push!(have_data, :percent_good)
        end
        # FIXME: add other code-recognition here
    end
    metadata["codes"] = codes # FIXME will users ever need this?
    metadata["have_data"] = have_data # FIXME is this useful, when user can do keys(x.data)?
    # Set up arrays
    # FIXME: add other array-allocation here
    if :velocity in have_data
        velocity = Array{Float64,3}(undef, metadata["nensembles"], metadata["ncells"], metadata["nbeams"])
    end
    if :correlation_magnitude in have_data
        correlation_magnitude = Array{UInt8,3}(undef, metadata["nensembles"], metadata["ncells"], metadata["nbeams"])
    end
    if :echo_intensity in have_data
        echo_intensity = Array{UInt8,3}(undef, metadata["nensembles"], metadata["ncells"], metadata["nbeams"])
    end
    if :percent_good in have_data
        percent_good = Array{UInt8,3}(undef, metadata["nensembles"], metadata["ncells"], metadata["nbeams"])
    end
    ne = metadata["nensembles"]
    nc = metadata["ncells"]
    nb = metadata["nbeams"]
    oad(debug, "  about to read $ne ensembles, each with $nc cells and $nb beams")
    for e in 1:ne
        p = D_[e] # pointer used thoughout the looop
        if buf[p] == 0 && buf[p+1] == 1
            p = p + 2 # skip the two-byte type indicator
            for c in 1:nc
                for b in 1:nb
                    velocity[e, c, b] = 0.001 * two_byte_signed(p)
                    p = p + 2
                end
            end
        end
        if buf[p] == 0 && buf[p+1] == 2
            p = p + 2 # skip the two-byte type indicator
            for c in 1:nc
                for b in 1:nb
                    correlation_magnitude[e, c, b] = buf[p]
                    p = p + 1
                end
            end
        end
        if buf[p] == 0 && buf[p+1] == 3
            p = p + 2 # skip the two-byte type indicator
            for c in 1:nc
                for b in 1:nb
                    echo_intensity[e, c, b] = buf[p]
                    p = p + 1
                end
            end
        end
        if buf[p] == 0 && buf[p+1] == 4
            p = p + 2 # skip the two-byte type indicator
            for c in 1:nc
                for b in 1:nb
                    percent_good[e, c, b] = buf[p]
                    p = p + 1
                end
            end
        end
        # FIXME: add other array-assignment here
    end
    if :velocity in metadata["have_data"]
        data["velocity"] = velocity
    end
    if :correlation_magnitude in metadata["have_data"]
        data["correlation_magnitude"] = correlation_magnitude
    end
    if :echo_intensity in metadata["have_data"]
        data["echo_intensity"] = echo_intensity
    end
    if :percent_good in metadata["have_data"]
        data["percent_good"] = percent_good
    end
    rval = Adp(metadata, data)
    # FIXME: do RDI files have a transformation matrix?
    oad(debug, "END read_adp_rdi()")
    rval
end
