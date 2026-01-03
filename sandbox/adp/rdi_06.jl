using Dates

debug = true

function find_rdi_chunks(buf; debug::Bool=false)
    nbuf = length(buf)
    start = 1
    while true # Find first 7f 7f byte pair, in case file starts mid-chunk
        if buf[start] == 0x7f & buf[start+1] == 0x7f
            break
        end
        start += 1
        if start >= nbuf - 1
            error("no 0x7f 0x74 in file $file")
        end
    end
    starts = Vector{Int64}()
    for chunk in 1:40
        if start >= nbuf # got to end of buffer before 
            println("EOF encountered after chunk $(chunk-1)")
            break
        end
        # Do next manually, since (I think) Julia obeys OS endianness
        #> bytes_to_check = Int16(reinterpret(UInt16, buf[2:3])[1])
        local bytes_to_check = buf[start+2] + 256 * buf[start+3]
        #println("chunk $chunk, start $start, bytes_to_check $bytes_to_check")
        #local bytes_to_read = bytes_to_check - 4
        number_of_data_types = buf[start+5]
        if number_of_data_types < 1 | number_of_data_types > 200
            error("something is wrong with number_of_data_types (=$number_of_data_types)")
        end
        if debug & chunk == 1
            if 6 != number_of_data_types
                println("FIXME: number of data types: ", number_of_data_types)
            end
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

function read_header(buf, start::Int64=1; debug::Bool=false)
    metadata = Dict()
    number_of_data_types = Int(buf[start+5])
    metadata["number_of_data_types"] = number_of_data_types
    if number_of_data_types < 1 | number_of_data_types > 200
        error("something is wrong with number_of_data_types (=$number_of_data_types)")
    end
    # data_offset in 2-byte elements
    data_offsets = Vector{Int}(undef, number_of_data_types)
    for i in 1:number_of_data_types
        tmp = start + 4 + 2 * i
        data_offsets[i] = buf[tmp] + 256 * buf[tmp+1]
    end
    metadata["data_offsets"] = data_offsets
    # Now look past 'header' to 'fixed leader', but
    # just for things that will not change over the
    # course of sampling.
    start_fl = start + 5 + 2 * number_of_data_types
    version_major = string(buf[start_fl+3])
    version_minor = string(buf[start_fl+4])
    metadata["version"] = version_major * "." * version_minor
    #println("Next are sys-conf")
    #system_configuration = [digits(buf[start_fl+5], base=2, pad=8); digits(buf[start_fl+6], base=2, pad=8)]
    #println("system_configuration $system_configuration")
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
    direction = sys_config_LSB[1] == 0 ? "down" : "up"
    metadata["direction"] = direction
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
    println("sys_config_LSB $sys_config_LSB")
    println("sys_config_MSB $sys_config_MSB")
    number_of_beams = Int(buf[start_fl+9])
    metadata["number_of_beams"] = number_of_beams
    number_of_cells = Int(buf[start_fl+10])
    metadata["number_of_cells"] = number_of_cells
    depth_cell_length = 0.01 * (buf[start_fl+13] + 256 * buf[start_fl+14])
    metadata["depth_cell_length"] = depth_cell_length
    bin1_distance = 0.01 * buf[start_fl+33] + 256 * buf[start_fl+34]
    metadata["bin1_distance"] = bin1_distance
    #beam_angle = Float64(buf[start_fl+59])
    #metadata["beam_angle"] = beam_angle
    metadata
end


file = "/Users/kelley/data/archive/sleiwex/2008/moorings/m09/adp/rdi_2615/raw/adp_rdi_2615.000"
file = "adp_rdi.000"
buf = read(file);
# Next takes 1 microsecond per chunk, after compilation
chunk_starts = find_rdi_chunks(buf; debug=true)
metadata = read_header(buf, chunk_starts[1]; debug=debug)
metadata["file"] = file

#println("chunk_starts: $chunk_starts")
println("metadata:")
display(metadata)
println("EXPECT data offsets 18 77 142 816 1154 1492")
println("EXPECT version 16.28")
println("EXPECT 4 beams, 84 cells")

first_leader_starts = chunk_starts .+ 6 .+ 2 * metadata["number_of_data_types"];

H_ = chunk_starts; # FIXME: rename throughout
FL_ = H_ .+ 6 .+ 2 * metadata["number_of_data_types"];
0 == buf[FL_[1]] || stop("problem @ FL_[1]")
0 == buf[FL_[1]+1] || stop("problem @ FL_[1] + 2")
VL_ = FL_ .+ 59;
0x80 == buf[VL_[1]] || error("problem w/ VL_starts[1]")
0x00 == buf[VL_[1]+1]

ensemble_number = buf[VL_.+2] + 245 * buf[VL_.+3]
println("ensemble_number $ensemble_number")

year = 2000 .+ buf[VL_.+4];
month = Int.(buf[VL_.+5]);
day = Int.(buf[VL_.+6]);
hour = Int.(buf[VL_.+7]);
minute = Int.(buf[VL_.+8]);
second = Int.(buf[VL_.+9]);
time = DateTime.(year, month, day, hour, minute, second);
display(time)
println("R time: 2008-06-25 10:00:00, 10:00:10, 10:00:40, 10:00:50, 10:01:00, 10:01:10, 10:01:20")

function two_byte_signed(i)
    #reinterpret(Int16, [buf[i], buf[i+1]])
    #signed(UInt16(byte_high)<<8|UInt16(byte_low))
    global buf
    signed(UInt16(buf[i+1]) << 8 | UInt16(buf[i]))
end

# sound_speed
# RDI p139 says bytes 15,16 so use 14,15 here
i = 14
sound_speed = buf[VL_.+i] .+ 256 .* buf[VL_.+(i+1)]
sound_speed = Float64.(two_byte_signed.(VL_ .+ 14))
println("sound_speed $sound_speed")
println("R soundSpeed 1497 1497 1497 1497 1497 1497 1497 1497 1497")

# heading RDI p139 says bytes 19,20 -- use 18,19 here
heading = 0.01 * two_byte_signed.(VL_ .+ 18)
println("heading: $heading")
println("R heading 278.14 277.31 276.78 276.39 276.56 277.07 277.56 277.47 276.98")

# pitch RDI p139 says bytes 21,22 -- use 20,21 here
pitch = 0.01 * two_byte_signed.(VL_ .+ 20)
println("pitch: $pitch")
println("R pitch 1.421236 1.241172 1.201080 1.140976 1.161010 1.171018 1.211098 1.161001 1.120942")

# roll RDI p139 says bytes 23,24 -- use 22,23 here
roll = 0.01 * two_byte_signed.(VL_ .+ 22)
println("roll: $roll")
println("R roll -2.39 -2.49 -2.43 -2.37 -2.39 -2.39 -2.44 -2.38 -2.35")

