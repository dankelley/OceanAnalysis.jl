using Dates, Plots

function key_insert(dict, key)
    if key in keys(dict)
        dict[key] += 1
    else
        dict[key] = 1
    end
end

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
        # Do byte shifts manually to be indepdent of machine endianness. (I know, Julia
        # has a way to do thati but I prefer having the code look like C.)
        local bytes_to_check = UInt16(buf[start+3]) << 8 | UInt16(buf[start+2])
        ntypes = buf[start+5]
        if ntypes < 1 | ntypes > 200
            error("something is wrong with ntypes (=$ntypes)")
        end
        if start + bytes_to_check + 1 > nbuf
            if debug > 0
                @warn "got to EOF while trying to read ensemble number $ensemble"
            end
            break
        end
        local checksum::UInt16 = 0
        for i in range(start, length=bytes_to_check)
            checksum += buf[i] # relies on overflow wrapping around zero
        end
        local desired_checksum = UInt16(buf[start+bytes_to_check+1]) << 8 | UInt16(buf[start+bytes_to_check])
        if checksum == desired_checksum
            push!(starts, start)
        else
            println("  bad checksum=$checksum (desired_checksum=$desired_checksum)")
        end
        start += bytes_to_check + 2
    end
    starts
end

# read the header, and compute a few things, for the setup of 'metadata'
function read_adp_rdi_header(buf, start::Int64=1)
    metadata = Dict()
    ntypes = Int(buf[start+5])
    metadata["ntypes"] = ntypes
    ntypes > 0 || error("ntypes=$ntypes is not a positive integer")
    ntypes < 201 || error("ntypes=$ntypes exceeds 200")
    # data_offset in 2-byte elements
    data_offsets = Vector{Int}(undef, ntypes)
    # FIXME: is it ok to read this just once per file?
    for i in 1:ntypes
        tmp = start + 4 + 2 * i
        data_offsets[i] = UInt16(buf[tmp+1]) << 8 | UInt16(buf[tmp])
    end
    metadata["data_offsets"] = data_offsets
    # Now look past 'header' to 'fixed leader', but just for things that will
    # not change over the course of sampling.
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
    nbeams = Int(buf[start_fl+9])
    metadata["nbeams"] = nbeams
    ncells = Int(buf[start_fl+10])
    metadata["ncells"] = ncells
    depth_cell_length = 0.01 * (UInt16(buf[start_fl+14]) << 8 | UInt16(buf[start_fl+13]))
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
    bin1_distance = 0.01 * (UInt16(buf[start_fl+34]) << 8 | UInt16(buf[start_fl+33]))
    metadata["bin1_distance"] = bin1_distance
    metadata["distance"] = range(bin1_distance, step=depth_cell_length, length=ncells)
    metadata
end

"""
    read_adp_rdi(filename::String, ensembles::Union{Int64,Vector{Int64}}=0; debug::Int64=0)

Read acoustic-Doppler profiler data in RDI "Workhorse-II' format

This function is designed to read the PD0 format, as described in Chapter
4 of Reference 1.  (During development, the results were compared with
those from the `read.adp.rdi()` function of the R `oce` package, which was
based on Reference 2.)

At present, only 4 data items can be read: `:velocity`
(with byte code 0x00 0x01), `:correlation_magnitude` (0x00 0x02),
`:echo_intensity`  (0x00 0x03) and `:percent_good` (0x00 0x04). More
types may be added later, as needs arise. (NB. the R code in
`oce::read.adp.rdi()` handles 18 types.)

# Arguments

- `filename` an ADCP file in the 'PD0' format as described in the Teledyne RD Instruments documentation (references 1 and 2).

- `ensembles` an indication of which ensembles (data profiles) to read.  This may be an singe integer or a vector of integers. In the first case, if `ensembles=0` then the whole file is read, otherwise the stated number of ensembles is read (provided that the file holds that number). In the second case, the value of `ensembles` dictates the indices of ensembles that are to be read. In both cases, the indices are trimmed to be from 1 to the number of ensembles in the file. The default is to read the whole file. and e.g. `ensembles=1:10:101` would read ensemble 1, ensemble 11, and so on, up to ensemble 101.

# Keywords

- `debug` an integer indicating whether to print information during processing. The default value of 0 means to work quietly, and any larger integer indicates to print some information.

# Examples

```juliadoc
using OceanAnalysis, Plots

# Load a sample file provided with the package
file = joinpath(dirname(dirname(pathof(OceanAnalysis))), "data", "adp_rdi.000");
adp = read_adp_rdi(file);

# Plot a timeseries of heading
plot(adp["time"], adp["heading"],
    ylab="Heading", label=false, framestyle=:box)

# Plot a heatmap of velocity in the first ensemble
heatmap(adp["velocity"][1, :, :], c=cgrad(:RdBu, rev=true))

# Plot a heatmap of velocity in the first bin vs time and distance
heatmap(adp["time"], adp["distance"], adp["velocity"][:,:,1],
    size=(800,600), ylab="Distance [m]", c=:RdBu)

# List other data in the 'adp' object
keys(adp.data)

# See a particular data item
adp["heading"]

# List the metadata in the 'adp' object
keys(adp.metadata)

# See a particular metadata item
adp["frequency"]
```

# References
1. Teledyne RD Instruments. “Workhorse II Commands and Output Data Format.” November 2025. P/N 957-6156-00. https://www.teledynemarine.com/en-us/support/SiteAssets/RDI/Manuals%20and%20Guides/Workhorse%20II/WorkHorse_Commands_and_Output_Data_Format.pdf.
2. Teledyne RD Instruments. “Workhorse Commands and Output Data Format.” 2010.
3. Teledyne RD Instruments. “Acoustic Doppler Current Profiler Principles of Operation: A Practical Primer.” January 2011. https://www.comm-tec.com/Docs/Manuali/RDI/BBPRIME.pdf.
"""
function read_adp_rdi(filename::String, ensembles::Union{Int64,StepRange{Int,Int},Vector{Int64}}=0; debug::Int64=0)
    function two_byte_unsigned(i) # could also use built-in (as for Int32 for ISM)
        UInt16(buf[i+1]) << 8 | UInt16(buf[i])
    end
    function two_byte_signed(i)
        signed(UInt16(buf[i+1]) << 8 | UInt16(buf[i]))
    end
    oad(debug, "read_adp_rdi() START")
    buf = read(filename)
    # H_ holds pointers to the starts of ensembles.
    oad(debug, "  About to determine the ensemble indices.")
    E_ = find_adp_rdi_ensembles(buf)
    nE_ = length(E_)
    # interpret ensembles, possibly subsetting H_
    if length(ensembles) == 1
        ensembles > -1 || error("negative 'ensembles' (here, $ensembles) are not allowed")
        if ensembles != 0
            E_ = E_[1:min(nE_, ensembles)]
        end
        oad(debug, "  Using $(length(E_)) of the $nE_ ensembles in the file.")
    else
        ensembles = ensembles[1 .< ensembles .< nE_]
        E_ = E_[ensembles]
        oad(debug, "  Using $(length(E_)) of the $nE_ ensembles in the file.")
    end
    nE_ = length(E_)
    oad(debug, "  About to read header information in first ensemble.")
    metadata = read_adp_rdi_header(buf, E_[1])
    data_offsets = metadata["data_offsets"]
    metadata["filename"] = filename
    data = Dict()
    metadata["nensembles"] = length(E_)
    # FL_ holds pointers to the starts of fixed-length headers (See Figure 8 of [1])
    FL_ = E_ .+ 6 .+ 2 * metadata["ntypes"]
    0 == buf[FL_[1]] || error("problem w/ buf[FL_[1]")
    0 == buf[FL_[1]+1] || error("problem w/ buf[FL_[1+1]")
    # VL_ holds pointers to the starts of variable-length headers
    VL_ = FL_ .+ 59 # (see Figure 8 of [1])
    0x80 == buf[VL_[1]] || error("problem w/ VL_starts[1]")
    0x00 == buf[VL_[1]+1]
    oad(debug, "  Inferring time-series information.")
    data["ensemble"] = buf[VL_.+2] + 256 * buf[VL_.+3]
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
    oad(debug, "  Determining data types (using data_offsets=$data_offsets).")
    data_types = Symbol[]
    for t in 1:metadata["ntypes"]
        codes[t, 1] = buf[metadata["data_offsets"][t].+1]
        codes[t, 2] = buf[metadata["data_offsets"][t].+2]
        if codes[t, :] == [0x00, 0x01]
            push!(data_types, :velocity)
        end
        if codes[t, :] == [0x00, 0x02]
            push!(data_types, :correlation_magnitude)
        end
        if codes[t, :] == [0x00, 0x03]
            push!(data_types, :echo_intensity)
        end
        if codes[t, :] == [0x00, 0x04]
            push!(data_types, :percent_good)
        end
        if codes[t, :] == [0x00, 0x05]
            push!(data_types, :status)
        end
        if codes[t, :] == [0x00, 0x06]
            push!(data_types, :bottom_track)
        end
        if codes[t, :] == [0x01, 0x59]
            push!(data_types, :ISM)
        end
        if codes[t, :] == [0x0C, 0x02]
            push!(data_types, :ambient_sound)
        end
        # FIXME: add other code-recognition here
    end
    metadata["codes"] = codes # FIXME will users ever need this?
    metadata["data_types"] = data_types # FIXME is this useful, when user can do keys(x.data)?
    ne = metadata["nensembles"]
    nc = metadata["ncells"]
    nb = metadata["nbeams"]
    # Set up storage that we fill as we read through the ensembles
    # FIXME: add other array-allocation here
    if :velocity in data_types
        oad(debug, "  Setting up storage for 'velocity' (a $(ne)x$(nc)x$(nb) array).")
        velocity = Array{Float64,3}(undef, ne, nc, nb)
    end
    if :correlation_magnitude in data_types
        oad(debug, "  Setting up storage for 'correlation_magnitude' (a $(ne)x$(nc)x$(nb) array).")
        correlation_magnitude = Array{UInt8,3}(undef, ne, nc, nb)
    end
    if :echo_intensity in data_types
        oad(debug, "  Setting up storage for 'echo_intensity' (a $(ne)x$(nc)x$(nb) array).")
        echo_intensity = Array{UInt8,3}(undef, ne, nc, nb)
    end
    if :percent_good in data_types
        oad(debug, "  Setting up storage for 'percent_good' (a $(ne)x$(nc)x$(nb) array).")
        percent_good = Array{UInt8,3}(undef, ne, nc, nb)
    end
    if :status in data_types
        @warn "FIXME: get storage for 'status'"
    end
    if :bottom_track in data_types
        @warn "FIXME: get storage for 'bottom_track' (Table 39, page 140+ of Reference 1)"
    end
    if :ambient_sound in data_types
        @warn "FIXME: get storage for 'ambient_sound'"
    end
    if :ISM in data_types
        oad(debug, "  Setting up ISM storage for 'ISM_acc' and 'ISM_mag' (both $(ne)x3 arrays).")
        ISM_valid = Vector{UInt8}(undef, ne)
        ISM_acc = Array{Int32,2}(undef, ne, 3)
        ISM_mag = Array{Int16,2}(undef, ne, 3)
    end
    data_offsets = metadata["data_offsets"]
    #<> oad(debug, "    data_offsets: $data_offsets")
    oad(debug, "  About to read $ne ensembles, each with $nc cells and $nb beams.")
    unhandled_data_types = Dict()
    #missed_status = 0
    #missed_bottom_track = 0
    #missed_ambient_sound = 0
    unknown_byte_sequences = Dict()
    for e in 1:ne
        #<> println("E_: $(E_)")
        #<> println("FL_: $(FL_)")
        #<> println("VL_: $(VL_)")
        #<> println("D_: $(D_)")
        p0 = E_[e] # pointer to start of ensemble
        for o in data_offsets
            p = p0 + o
            #<>println("Examine at p0=$p0, o=$o therefore p=$p. Five before and after are:")
            #<>for iii in range(-5, 5)
            #<>    println("  buf[", p + iii, "]: $(repr(buf[p+iii]))")
            #<>end
            if buf[p] == 0x00 && buf[p+1] == 0x00
                #println("ignoring 0x00 0x00 chunk")
            elseif buf[p] == 0x080 && buf[p+1] == 0x00
                #println("ignoring 0x80 0x00 chunk")
            elseif buf[p] == 0x00 && buf[p+1] == 0x01
                pp = p + 2
                #<> println("At e=$e, o=$o, p=$p try to read 'velocity'")
                for c in 1:nc
                    for b in 1:nb
                        velocity[e, c, b] = 0.001 * two_byte_signed(pp)
                        pp = pp + 2
                    end
                end
            elseif buf[p] == 0x00 && buf[p+1] == 0x02
                #<> println("At e=$e, o=$o, p=$p try to read 'correlation_magnitude'")
                pp = p + 2
                for c in 1:nc
                    for b in 1:nb
                        correlation_magnitude[e, c, b] = buf[pp]
                        pp = pp + 1
                    end
                end
            elseif buf[p] == 0x00 && buf[p+1] == 0x03
                #<> println("At e=$e, o=$o, p=$p try to read 'echo_intensity'")
                pp = p + 2
                for c in 1:nc
                    for b in 1:nb
                        echo_intensity[e, c, b] = buf[pp]
                        pp = pp + 1
                    end
                end
            elseif buf[p] == 0x00 && buf[p+1] == 0x04
                #<> println("At e=$e, o=$o, p=$p try to read 'percent_good'")
                pp = p + 2
                for c in 1:nc
                    for b in 1:nb
                        percent_good[e, c, b] = buf[pp]
                        pp = pp + 1
                    end
                end
            elseif buf[p] == 0x01 && buf[p+1] == 0x59
                # ISM See Table 41 on page 144 of Reference 1. (Note that the
                # description there is quite confusing.)
                ISM_valid[e] = buf[p+2]
                # Examination of a file suggests acc is in milli-gravity units
                ISM_acc[e, 1] = ltoh(reinterpret(Int32, buf[(p).+(3:6)])[1])
                ISM_acc[e, 2] = ltoh(reinterpret(Int32, buf[(p).+(7:10)])[1])
                ISM_acc[e, 3] = ltoh(reinterpret(Int32, buf[(p).+(11:14)])[1])
                ISM_mag[e, 1] = ltoh(two_byte_signed(p + 15))
                ISM_mag[e, 2] = ltoh(two_byte_signed(p + 17))
                ISM_mag[e, 3] = ltoh(two_byte_signed(p + 19))
            elseif buf[p] == 0x00 && buf[p+1] == 0x05
                key_insert(unhandled_data_types, "status")
            elseif buf[p] == 0x00 && buf[p+1] == 0x06
                key_insert(unhandled_data_types, "bottom_track")
            elseif buf[p] == 0x0C && buf[p+1] == 0x02
                key_insert(unhandled_data_types, "ambient_sound")
            else
                key_insert(unknown_byte_sequences, repr(buf[p]) * "," * repr(buf[p+1]))
            end
            # FIXME: add other array-assignment here
            # FIXME (bottom_track): see Table 39, page 140+ of Reference 1 and oce/R/adp.rdi.R
        end
    end
    if length(unknown_byte_sequences) > 0
        println("Table of unrecognized byte sequences")
        display(unknown_byte_sequences)
    end
    if length(unhandled_data_types) > 0
        println("Table of unhandled data types (FIXME: code for them as cases arise)")
        display(unhandled_data_types)
    end
    # Insert elements into what will become rval.data
    if :velocity in metadata["data_types"]
        data["velocity"] = velocity
    end
    if :correlation_magnitude in metadata["data_types"]
        data["correlation_magnitude"] = correlation_magnitude
    end
    if :echo_intensity in metadata["data_types"]
        data["echo_intensity"] = echo_intensity
    end
    if :percent_good in metadata["data_types"]
        data["percent_good"] = percent_good
    end
    if :ISM in metadata["data_types"]
        data["ISM_valid"] = ISM_valid
        data["ISM_acc"] = ISM_acc
        data["ISM_mag"] = ISM_mag
    end
    rval = Adp(metadata, data)
    oad(debug, "END read_adp_rdi()")
    rval
end
