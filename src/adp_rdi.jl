using Dates, Plots, BenchmarkTools

function key_insert(dict, key)
    if key in keys(dict)
        dict[key] += 1
    else
        dict[key] = 1
    end
end

function find_adp_rdi_ensembles(buf::Vector{UInt8}; debug::Integer=0)
    nbuf = length(buf)
    start = 1
    while true # Find first 7f 7f byte pair, in case file starts mid-ensemble
        if buf[start] == 0x7f & buf[start+1] == 0x7f
            break
        end
        start += 1
        if start >= nbuf - 1
            throw(FormatException("This file does not have any 0x7f 0x74 byte pairs"))
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
        local bytes_to_check = reinterpret(Int16, buf[start.+(2:3)])[1]
        ntypes = buf[start+5]
        if ntypes < 1 | ntypes > 200
            throw(FormatException("Invalid ntypes ($ntypes); expecting an integer from 1 to 200"))
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
        local desired_checksum = reinterpret(UInt16, buf[(bytes_to_check+start).+(0:1)])[1]
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
function read_adp_rdi_header(buf::Vector{UInt8}, start::Int64=1)
    metadata = Dict()
    ntypes = Int(buf[start+5])
    metadata["ntypes"] = ntypes
    ntypes > 0 || throw(FormatException("inferred ntypes must be a positive integer, but it is $ntypes"))
    ntypes < 201 || throw(FormatException("inferred ntypes must be < 200, but it is $ntypes"))
    # data_offset in 2-byte elements
    data_offsets = Vector{Int}(undef, ntypes)
    # FIXME: is it ok to read this just once per file?
    for i in 1:ntypes
        tmp = start + 4 + 2 * i
        data_offsets[i] = reinterpret(UInt16, buf[(tmp).+(0:1)])[1]
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
        frequency = 0 # FIXME: handle other cases
    end
    metadata["frequency"] = frequency
    metadata["direction"] = sys_config_LSB[1] == 0 ? :down : :up
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
    A = 1.0 / (2.0 * sind(metadata["beam_angle"]))
    B = 1.0 / (4.0 * cosd(metadata["beam_angle"]))
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
    depth_cell_length = 0.01 * reinterpret(Int16, buf[(start_fl).+(13:14)])[1]
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
    bin1_distance = 0.01 * reinterpret(UInt16, buf[(start_fl).+(33:34)])[1]
    metadata["bin1_distance"] = bin1_distance
    metadata["distance"] = range(bin1_distance, step=depth_cell_length, length=ncells)
    metadata
end



"""
    read_adp_rdi(filename::String, ensembles::Union{Int64,StepRange{Int64,Int64},Vector{Int64}}=0; debug::Integer=0)

Read acoustic-Doppler profiler data in RDI "Workhorse-II' format

This function, still in an early phase of development, is designed to
read the Teledyne-RDI Workhorse-II PD0 format, as described in Chapter
4 of Reference 1. This format replaces the Workhorse-I PD0 format of
Reference 2, which was used as the basis for the `read.adp.rdi()`
function of the R `oce` package. 

It is worth noting that the `oce` code handles other Teledyne-RDI formats
in addition to the Workhorse variety, and it has been tested
well with a variety of datasets. It is possible to call R from Julia,
so users ought to consider doing so on files that the present
function cannot handle.

# Arguments

- `filename` an ADCP file in the 'PD0' format as described in the Teledyne RD Instruments documentation (Reference 1).

- `ensembles` an indication of which ensembles (data profiles) to read.  This may be an single integer or a vector of integers. In the first case, if `ensembles=0` then the whole file is read, otherwise the stated number of ensembles is read (provided that the file holds that number). In the second case, the value of `ensembles` dictates the indices of ensembles that are to be read. In both cases, the indices are trimmed to be from 1 to the number of ensembles in the file. The default is to read the whole file. and e.g. `ensembles=1:10:101` would read ensemble 1, ensemble 11, and so on, up to ensemble 101.

# Keywords

- `debug` an integer indicating whether to print information during processing. The default value of 0 means to work quietly, and any larger integer indicates to print some information.

# Examples

```julia
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
function read_adp_rdi(filename::String, ensembles::Union{Int64,StepRange{Int64,Int64},Vector{Int64}}=0; debug::Integer=0)
    oad(debug, "read_adp_rdi() START")
    filename = expanduser(filename)
    buf = read(filename)
    # H_ holds pointers to the starts of ensembles.
    oad(debug, "  About to determine the ensemble indices.")
    E_ = find_adp_rdi_ensembles(buf)
    nE_ = length(E_)
    # interpret ensembles, possibly subsetting H_
    if length(ensembles) == 1
        ensembles > -1 || throw(FormatException("negative 'ensembles' (here, $ensembles) are not allowed"))
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
    0 == buf[FL_[1]] || throw(FormatException("problem w/ buf[FL_[1]"))
    0 == buf[FL_[1]+1] || throw(FormatException("problem w/ buf[FL_[1+1]"))
    # VL_ holds pointers to the starts of variable-length headers
    VL_ = FL_ .+ 59 # (see Figure 8 of [1])
    0x80 == buf[VL_[1]] || throw(FormatException("problem w/ VL_starts[1]"))
    0x00 == buf[VL_[1]+1]
    # comb is used for getting two-byte entries
    comb2 = sort([VL_; VL_ .+ 1])
    #println("time of ensemble creation step 1")
    #@time buf2 = buf[comb2.+2] # sort([VL_ .+ 2; VL_ .+ 3])]
    #println("time of ensemble creation step 2")
    #?@time int16_2 = ltoh.(reinterpret(Int16, buf2)) #[sort([VL_ .+ 2; VL_ .+ 3])]))
    oad(debug, "  Inferring ensemble.")
    #@time data["ensemble"] = convert(Array{Int64}, reinterpret(Int16, buf[comb2.+2]))
    data["ensemble"] = convert(Array{Int64}, reinterpret(Int16, buf[comb2.+2]))
    #println("time of ensemble creation step 3")
    #@time data["ensemble"] = copy(int16_2)
    oad(debug, "  Inferring time-series information.")
    #<testing timing> year = 2000 .+ convert(Array{Int64}, reinterpret(UInt8, buf[VL_.+4]))
    #<testing timing> month = convert(Array{Int64}, reinterpret(UInt8, buf[VL_.+5]))
    #<testing timing> day = convert(Array{Int64}, reinterpret(UInt8, buf[VL_.+6]))
    #<testing timing> hour = convert(Array{Int64}, reinterpret(UInt8, buf[VL_.+7]))
    #<testing timing> minute = convert(Array{Int64}, reinterpret(UInt8, buf[VL_.+8]))
    #<testing timing> second = convert(Array{Int64}, reinterpret(UInt8, buf[VL_.+9]))
    #<testing timing> println("infer time (almost 1M allocations for $(length(year)) values.)")
    #<testing timing> println("typeof(year):   $(typeof(year))")
    #<testing timing> println("typeof(month):  $(typeof(month))")
    #<testing timing> println("typeof(day):    $(typeof(day))")
    #<testing timing> println("typeof(hour):   $(typeof(hour))")
    #<testing timing> println("typeof(minute): $(typeof(minute))")
    #<testing timing> println("typeof(second): $(typeof(second))")
    #<testing timing> println("inferring time:")
    #<testing timing> @time data["time"] = DateTime.(year, month, day, hour, minute, second + 0.01 * second100)
    year = 2000.0 .+ reinterpret(UInt8, buf[VL_.+4])
    month = reinterpret(UInt8, buf[VL_.+5])
    day = reinterpret(UInt8, buf[VL_.+6])
    hour = reinterpret(UInt8, buf[VL_.+7])
    minute = reinterpret(UInt8, buf[VL_.+8])
    second = reinterpret(UInt8, buf[VL_.+9]) .+ 0.01 * reinterpret(UInt8, buf[VL_.+10])
    data["time"] = DateTime.(year, month, day, hour, minute, second)
    # sound_speed: RDI p139 says bytes 15,16 so use 14,15 here, i.e. comb2.+14
    data["sound_speed"] = convert(Array{Float64}, reinterpret(Int16, buf[comb2.+14]))
    # heading: RDI p139 says bytes 19,20 -- use 18,19 here, i.e. comb.+18
    # Using convert() takes 14 allocations and 1.3 KiB.
    # Using Float64.() takes 174.38 k allocations and 8.772 MiB
    data["heading"] = 0.01 * convert(Array{Float64}, reinterpret(Int16, buf[comb2.+18]))
    # pitch RDI p139 says bytes 21,22 -- use 20,21 here
    # NOTE: pitch is 'corrected' in a few lines
    pitch = 0.01 * convert(Array{Float64}, reinterpret(Int16, buf[comb2.+20]))
    # roll RDI p139 says bytes 23,24 -- use 22,23 here
    roll = 0.01 * convert(Array{Float64}, reinterpret(Int16, buf[comb2.+22]))
    data["roll"] = roll
    # Pitch correction. See page 14 of 'adcp coordinate transformation.pdf
    #println("save new pitch")
    #@time data["pitch"] = atand.(tand.(pitch) ./ cosd.(roll))
    data["pitch"] = atand.(tand.(pitch) ./ cosd.(roll))
    codes = Array{UInt8,2}(undef, metadata["ntypes"], 2)
    oad(debug, "  Determining data types (using data_offsets=$data_offsets).")
    data_types = Symbol[]
    for t in 1:metadata["ntypes"]
        codes[t, 1] = buf[metadata["data_offsets"][t].+1]
        codes[t, 2] = buf[metadata["data_offsets"][t].+2]
        if codes[t, :] == [0x00, 0x01]
            push!(data_types, :velocity)
        elseif codes[t, :] == [0x00, 0x02]
            push!(data_types, :correlation_magnitude)
        elseif codes[t, :] == [0x00, 0x03]
            push!(data_types, :echo_intensity)
        elseif codes[t, :] == [0x00, 0x04]
            push!(data_types, :percent_good)
        elseif codes[t, :] == [0x00, 0x05]
            push!(data_types, :status)
        elseif codes[t, :] == [0x00, 0x06]
            push!(data_types, :bottom_track)
        elseif codes[t, :] == [0x01, 0x59]
            push!(data_types, :ISM)
        elseif codes[t, :] == [0x0C, 0x02]
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
        oad(debug, "  Setting up storage for 'velocity' (a $(ne)×$(nc)×$(nb) Float64 array).")
        velocity = Array{Float64,3}(undef, ne, nc, nb)
    end
    if :correlation_magnitude in data_types
        oad(debug, "  Setting up storage for 'correlation_magnitude' (a $(ne)×$(nc)×$(nb) UInt8 array).")
        correlation_magnitude = Array{UInt8,3}(undef, ne, nc, nb)
    end
    if :echo_intensity in data_types
        oad(debug, "  Setting up storage for 'echo_intensity' (a $(ne)×$(nc)×$(nb) UInt8 array).")
        echo_intensity = Array{UInt8,3}(undef, ne, nc, nb)
    end
    if :percent_good in data_types
        oad(debug, "  Setting up storage for 'percent_good' (a $(ne)×$(nc)×$(nb) UInt8 array).")
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
        oad(debug, "  Setting up ISM storage for 'ISM_acc' and 'ISM_mag' (both $(ne)×3 Int32 arrays).")
        ISM_valid = Vector{UInt8}(undef, ne)
        ISM_acc = Array{Int32,2}(undef, ne, 3)
        ISM_mag = Array{Int16,2}(undef, ne, 3)
    end
    data_offsets = metadata["data_offsets"]
    oad(debug, "  About to read $ne ensembles, each with $nc cells and $nb beams.")
    unhandled_data_types = Dict()
    unknown_byte_sequences = Dict()
    #println("fill in arrays")
    #@time for e in 1:ne
    for e in 1:ne
        p0 = E_[e] # pointer to start of ensemble
        for o in data_offsets
            p = p0 + o
            # Skip 0x00,0x00 and 0x080,0x00 because both handled as time-series
            if buf[p] == 0x00 && buf[p+1] == 0x00
                # handled elsewhere
            elseif buf[p] == 0x80 && buf[p+1] == 0x00
                # handled elsewhere
            elseif buf[p] == 0x00 && buf[p+1] == 0x01
                tmp = reinterpret(Int16, buf[range(p + 2, length=2 * nb * nc)])
                bad = tmp .== -32768 # bad velocities are set to –32768 (page 155 of Reference 1)
                tmp = 0.001 * tmp
                tmp[bad] .= NaN
                velocity[e, :, :] = transpose(reshape(convert(Array{Float64}, tmp), nb, nc))
            elseif buf[p] == 0x00 && buf[p+1] == 0x02
                correlation_magnitude[e, :, :] = transpose(reshape(buf[range(p + 2, length=nb * nc)], nb, nc))
            elseif buf[p] == 0x00 && buf[p+1] == 0x03
                echo_intensity[e, :, :] = transpose(reshape(buf[range(p + 2, length=nb * nc)], nb, nc))
            elseif buf[p] == 0x00 && buf[p+1] == 0x04
                percent_good[e, :, :] = transpose(reshape(buf[range(p + 2, length=nb * nc)], nb, nc))
            elseif buf[p] == 0x01 && buf[p+1] == 0x59
                # ISM See (the confusing) Table 41 on page 144 of Reference 1.
                ISM_valid[e] = buf[p+2]
                ISM_acc[e, 1] = reinterpret(Int32, buf[(p).+(3:6)])[1]
                ISM_acc[e, 2] = reinterpret(Int32, buf[(p).+(7:10)])[1]
                ISM_acc[e, 3] = reinterpret(Int32, buf[(p).+(11:14)])[1]
                ISM_mag[e, 1] = reinterpret(Int16, buf[(p).+(15:16)])[1]
                ISM_mag[e, 2] = reinterpret(Int16, buf[(p).+(17:18)])[1]
                ISM_mag[e, 3] = reinterpret(Int16, buf[(p).+(19:20)])[1]
            elseif buf[p] == 0x00 && buf[p+1] == 0x05
                key_insert(unhandled_data_types, "status")
            elseif buf[p] == 0x00 && buf[p+1] == 0x06
                # FIXME (bottom_track): see Table 39, page 140+ of Reference 1 and oce/R/adp.rdi.R
                key_insert(unhandled_data_types, "bottom_track")
            elseif buf[p] == 0x0C && buf[p+1] == 0x02
                key_insert(unhandled_data_types, "ambient_sound")
            else
                key_insert(unknown_byte_sequences, repr(buf[p]) * "," * repr(buf[p+1]))
            end
            # FIXME: add other array-assignment here
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


"""
    beam_to_xyz(adp::Adp; debug::Integer=0)

    Change velocity in an RDI Adp object from beam to xyz coordinates

This is done by using the `transformation_matrix` that is stored within `adp`.  See
[`read_adp_rdi`](@ref) for how to read an RDI [`Adp`](@ref) object, and
[`xyz_to_enu`](@ref) for how to convert it from xyz to enu coordinates.

# Examples

```julia
using OceanAnalysis, Plots
file = joinpath(dirname(dirname(pathof(OceanAnalysis))),
    "data", "adp_rdi.000")
adp = read_adp_rdi(file);
adp_xyz = beam_to_xyz(adp);
v = adp.data["velocity"];
V = adp_xyz.data["velocity"];
CM = cgrad(:RdBu, rev=true);
p1 = heatmap(transpose(v[:, :, 1]), c=CM, title="beam 1", titlefontsize=9);
p2 = heatmap(transpose(v[:, :, 2]), c=CM, title="beam 2", titlefontsize=9);
p3 = heatmap(transpose(v[:, :, 3]), c=CM, title="beam 3", titlefontsize=9);
p4 = heatmap(transpose(v[:, :, 4]), c=CM, title="beam 4", titlefontsize=9);
pu = heatmap(transpose(V[:, :, 1]), c=CM, title="u", titlefontsize=9);
pv = heatmap(transpose(V[:, :, 2]), c=CM, title="v", titlefontsize=9);
pw = heatmap(transpose(V[:, :, 3]), c=CM, title="w", titlefontsize=9);
pe = heatmap(transpose(V[:, :, 4]), c=CM, title="err", titlefontsize=9);
plot(p1, p2, p3, p4, layout=(4, 1), size=(1000, 700))
plot(pu, pv, pw, pe, layout=(4, 1), size=(1000, 700))
```

"""
function beam_to_xyz(adp::Adp; debug::Integer=0)
    oad(debug, "beam_to_xyz() BEGIN")
    :beam == adp["coordinate_system"] || throw(FormatException("coordinate_system must be :beam, but it is :", adp["coordinate_system"]))
    T = adp["transformation_matrix"]
    v = adp.data["velocity"]
    dim = size(v)
    dim[3] == 4 || error("beam_to_xyz only works for 4-beam Workhorse data")
    :beam == adp["coordinate_system"] || throw(FormatException("coordinate_system must be :beam, but it is ", adp["coordinate_system"]))
    ṽ = Array{Float64}(undef, dim)
    # Method 1 (see notes.md for why this was used)
    TT = transpose(T)
    ne = dim[1]
    for i in 1:ne
        ṽ[i, :, :] = v[i, :, :] * TT
    end
    # Method 2 (see notes.md for why this was not used)
    #  ṽ[:, :, 1] .= T[1, 1] * v[:, :, 1] .+ T[1, 2] * v[:, :, 2] .+ T[1, 3] * v[:, :, 3] .+ T[1, 4] * v[:, :, 4]
    #  ṽ[:, :, 2] .= T[2, 1] * v[:, :, 1] .+ T[2, 2] * v[:, :, 2] .+ T[2, 3] * v[:, :, 3] .+ T[2, 4] * v[:, :, 4]
    #  ṽ[:, :, 3] .= T[3, 1] * v[:, :, 1] .+ T[3, 2] * v[:, :, 2] .+ T[3, 3] * v[:, :, 3] .+ T[3, 4] * v[:, :, 4]
    #  ṽ[:, :, 4] .= T[4, 1] * v[:, :, 1] .+ T[4, 2] * v[:, :, 2] .+ T[4, 3] * v[:, :, 3] .+ T[4, 4] * v[:, :, 4]
    data = copy(adp.data)
    data["velocity"] = ṽ
    metadata = copy(adp.metadata)
    metadata["coordinate_system"] = :xyz
    rval = Adp(metadata, data)
    oad(debug, "END beam_to_xyz()")
    rval
end


"""
    xyz_to_enu(adp::Adp; declination::Float64=0.0, debug::Integer=0)

    Change velocity in an RDI Workhorse Adp object from xyz to enu coordinates

This is done by using the `heading`, `pitch` and `roll` vectors that are stored
within `adp`.  Note that `declination` is added to `heading`, to allow
for compass correction. See [`read_adp_rdi`](@ref) for how to read an RDI [`Adp`](@ref)
object, and [`beam_to_xyz`](@ref) for how to convert it from beam to xyz coordinates.

# Examples

```julia
using OceanAnalysis, Plots
file = joinpath(dirname(dirname(pathof(OceanAnalysis))),
    "data", "adp_rdi.000")
beam = read_adp_rdi(file);
xyz = beam_to_xyz(beam);
enu = xyz_to_enu(xyz);
v = enu["velocity"];
```
"""
function xyz_to_enu(adp::Adp; declination::Float64=0.0, debug::Integer=0)
    oad(debug, "xyz_to_enu() BEGIN")
    :xyz == adp["coordinate_system"] || error("coordinate_system must be :xyz, but it is :", adp["coordinate_system"])
    v = adp.data["velocity"]
    dim = size(v)
    dim[3] == 4 || error("xyz_to_enu only works for 4-beam Workhorse data")
    #ṽ = Array{Float64}(undef, dim)
    ṽ = copy(v)
    # FIXME: orientation
    h = declination .+ adp["heading"]
    p = adp["pitch"]
    r = adp["roll"]
    ch = cosd.(h)
    sh = sind.(h)
    cp = cosd.(p)
    sp = sind.(p)
    cr = cosd.(r)
    sr = sind.(r)
    # We need factors to handle instrument direction.  This is explained
    # in RDI documents referred to in oce/R/adp.R near line 3674
    direction = adp["direction"]
    if direction == :up
        fac = [-1.0; 1.0; -1.0]
    elseif direction == :down
        fac = [-1.0; 1.0; 1.0]
    else
        error("adp[\"direction\"] is :", direction, " but it needs to be :up or :down")
    end
    #@warn "Assuming upward-pointing RDI (see p11 of RDI Coordinate Transformation manual (July 1998)"
    # in oce:
    #    starboard <- -res@data$v[, , 1] # p11 "RDI Coordinate Transformation Manual" (July 1998)
    #    forward <- res@data$v[, , 2] # p11 "RDI Coordinate Transformation Manual" (July 1998)
    #    mast <- -res@data$v[, , 3] # p11 "RDI Coordinate Transformation Manual" (July 1998)
    # Checking for type instability -- none, though, so why all the allocations?
    #println("type check")
    #println("  typeof ṽ: ", typeof(ṽ))
    #println("  typeof fac: ", typeof(fac))
    #println("  typeof v: ", typeof(v))
    #println("  typeof ch: ", typeof(ch))
    #println("  typeof sh: ", typeof(sh))
    #println("  typeof cp: ", typeof(cp))
    #println("  typeof sp: ", typeof(sp))
    #println("  typeof cr: ", typeof(cr))
    #println("  typeof sr: ", typeof(sr))
    # Saving CH, etc and V1, etc. drops time by 10% and also drops alloc by factor 2
    #println("time for xyz->enu loop. Why so many allocations?")
    #@time for i in 1:dim[1]
    for i in 1:dim[1]
        CH = ch[i]
        SH = sh[i]
        CP = cp[i]
        SP = sp[i]
        CR = cr[i]
        SR = sr[i]
        for j in 1:dim[2]
            V1 = fac[1] * v[i, j, 1]
            V2 = fac[2] * v[i, j, 2]
            V3 = fac[3] * v[i, j, 3]
            ṽ[i, j, 1] =
                V1 * (CH * CR + SH * SP * SR) +
                V2 * (SH * CP) +
                V3 * (CH * SR - SH * SP * CR)
            ṽ[i, j, 2] =
                V1 * (-SH * CR + CH * SP * SR) +
                V2 * (CH * CP) +
                V3 * (-SH * SR - CH * SP * CR)
            ṽ[i, j, 3] =
                V1 * (-CP * SR) +
                V2 * SP +
                V3 * (CP * CR)
            #ṽ[i, j, 4] = v[i, j, 4] # copy error field directly
        end
    end
    #        east[i] =
    #            starboard[i] * ( CH * CR + SH * SP * SR ) +
    #            forward[i]   * ( SH * CP                ) +
    #            mast[i]      * ( CH * SR - SH * SP * CR );
    #        north[i] =
    #            starboard[i] * (-SH * CR + CH * SP * SR ) +
    #            forward[i]   * ( CH * CP                ) +
    #            mast[i]      * (-SH * SR - CH * SP * CR );
    #        up[i] =
    #            starboard[i] * (               -CP * SR ) +
    #            forward[i]   * ( SP                     ) +
    #            mast[i]      * (                CP * CR );
    data = copy(adp.data)
    data["velocity"] = ṽ
    metadata = copy(adp.metadata)
    metadata["coordinate_system"] = :enu
    rval = Adp(metadata, data)
    oad(debug, "END xyz_to_enu()")
    rval
end

