"""
    dt4_expand_rle!(buf::Vector{UInt8}, rval::Vector{UInt8}; byte_per_sample::Int64=2, debug::Int64=0)

Expand a byte sequence according to the scheme explained in Section 5.3.1 of
Reference 1.

# Arguments

- `buf::Vector{UInt8}` input buffer, allocated in the calling code to hold `2*ns` bytes, where `ns` is as defined as in Reference 1.

- `rval::Vector{UInt8}` output buffer, allocated in the calling code to hold `2*spp` bytes, where `spp` is defined as in Reference 1.

- `byte_per_sample` either 2 (for single-beam pings) or 4.  The latter case has not been checked with sample data.

- `debug` indicator of debugging level. If this exceeds 0, some information is printed during processing.

# References

1. C code in section 5.3.1 of BioSonics Advanced Digital Hydroacoustics. “DT4 Data File Format Specification.” BioSonics, May 2017.

"""
function dt4_expand_rle!(buf::Vector{UInt8}, rval::Vector{UInt8}; byte_per_sample::Int64=2, debug::Int64=0)
    if byte_per_sample != 2
        @warn "dt4_expand_rle!() not tested on 4-byte samples"
    end
    nbuf = length(buf)
    nrval = length(rval)
    if debug > 0
        println("nbuf: $nbuf, nrval: $nrval")
    end
    i = 1 # pointer to buf
    k = 1 # pointer to rval
    # We need to look at buf_in[i] and also buf_in[i+1]
    while i < nbuf # FIXME: 4-byte case needs to end earlier
        if debug > 0 && (i < 5 || i > (nbuf - 5))
            println("TOP OF WHILE LOOP -- i: $i (nb nbuf: $nbuf)")
        end
        #println("  i: $i")
        b1 = buf[i]
        i += 1
        b2 = buf[i]
        i += 1
        if byte_per_sample == 4
            b3 = buf[i]
            i += 1
            b4 = buf[i]
            i += 1
        end
        if b2 == 0xff
            # insert repeated zeros
            n = b1 + 2
            while n > 0
                if debug > 0
                    println("  repeating for n>0 with current n=$n")
                end
                if k < nrval
                    rval[k] = 0x00
                    k += 1
                    rval[k] = 0x00
                    k += 1
                    if byte_per_sample == 4
                        rval[k] = 0x00
                        k += 1
                        rval[k] = 0x00
                        k += 1
                    end
                    n -= 1
                else
                    if debug > 0
                        println("FIXME break to prevent overfill (will this ever happen?)")
                    end
                    break # prevent overfill (probably will never happen)
                end
            end
        else
            if k < nrval
                rval[k] = b1
                k += 1
                rval[k] = b2
                k += 1
                if byte_per_sample == 4
                    rval[k] = b3
                    k += 1
                    rval[k] = b4
                    k += 1
                end
            else
                if debug > 0
                    println("break at line 78")
                end
                break
            end
        end
        if debug > 0 && (i < 5 || i > (nbuf - 5))
            println("BOTTOM OF WHILE LOOP -- i: $i (nb nbuf: $nbuf)")
        end
    end
    # zero-fill to the end of rval
    while k < nrval
        if debug > 0
            println("zero-filling at end (k=$k, nrval=$nrval)")
        end
        rval[k] = 0x00
        k += 1
        rval[k] = 0x00
        k += 1
        if byte_per_sample == 4
            rval[k] = 0x00
            k += 1
            rval[k] = 0x00
            k += 1
        end
    end
end

function biosonic_float(buf::Vector{UInt8})
    nbuf = length(buf)
    println("nbuf: $nbuf")
    i = 1
    k = 1
    nrval = Int64(floor(nbuf / 2))
    println("nrval: $nrval")
    rval = Vector{UInt16}(undef, nrval)
    while i < nbuf
        b = reinterpret(UInt16, buf[(i).+(0:1)])[1]
        mantissa = b & 0x0FFF
        exponent = (b & 0xF000) >> 12
        if exponent == 0
            rval[k] = mantissa
        else
            rval[k] = (mantissa + 0x1000) << (exponent - 1)
        end
        k += 1
        i += 2
    end
    reverse(convert(Vector{Float64}, rval))
end

"""
    read_echosounder(filename::String; channel::Int64=1, tuples::Int64=0, debug=0)

    Read data from a Biosonics scientific echosounder.

This is a very provisional version of the function, which locates what Biosonics calls data tuples, and examines only some of them, and only in shallow ways. At the moment, 'Time' tuples (code 0x000F or 0x0020) are recognized and parsed (although the times are not used yet). The next goal is to handle "Single-Beam Ping" tuples (code 0x0015) first, before (perhaps) considering moving on to others. The R/oce function `read.echosounder()` will be used to check on whether the present function is working.

# Arguments

- `filename` string naming the file to be read.  It must be in Biosonics DT4 format (reference 1).

# Keywords

- `channel` an Int64 giving the channel number to read. The default is 1. In the file named in the Examples section, there are two channels, numbered 1 and 2.

- `tuples` (*temporary keyword*) an Int64 giving the number of tuples to read.  The default value of 0 means to read the whole file. This keyword is mainly to help in development and is likely to be removed when the function is in later stages of development.

- `debug` an Int64 value indicating whether to print messages during processing. By default, this is 0, meaning to work quietly.


# Examples
```julia
# This test will only work if a particular file exists
using OceanAnalysis
filename = "/Users/kelley/Dropbox/data/archive/sleiwex/2008/fielddata/2008-07-01/Merlu/Biosonics/20080701_163942.dt4"
if isfile(filename)
    e = read_echosounder(filename; debug=1);
end
```

# References

1.BioSonics Advanced Digital Hydroacoustics. “DT4 Data File Format
  Specification.” BioSonics, May 2017. This is available (after
  registratration) online at
  https://www.biosonicsinc.com/support/customer-downloads/
"""
function read_echosounder(filename::String; channel::Int64=1, tuples::Int64=0, debug=0)
    oad(debug, "read_echosounder() START")
    filename = expanduser(filename)
    first = true # DEBUGGING DAN
    channels = DataFrame(channel_number=Int64[], np=Int64[], spp=Int64[])
    last_time = unix2datetime(0.0) # overwritten later
    @time buf = read(filename)
    file_size = length(buf)
    offset = 0
    tuple = 1
    while offset < file_size
        N = convert(Int64, reinterpret(UInt16, buf[(offset).+(1:2)])[1])
        code = reinterpret(UInt16, buf[(offset).+(3:4)])[1]
        oad(debug, "  tuple: $tuple, offset: $offset, N: $N, code: $(repr(code))")
        if code == 0xFFFF
            oad(debug, "    Signature (start of file)")
            check = reinterpret(UInt16, buf[(offset).+(5:6)])[1]
            if check == 0xadff
                oad(debug, "      File passes first of 2 checks")
            else
                error("malformed file (bytes 5:6 should b e 0xadff but they are $(repr(check))")
            end
            # Skip 8 unused bytes...
            # A second check on file type
            check = reinterpret(UInt32, buf[15:18])[1]
            if check == 0xfef82111
                oad(debug, "      File passes second of 2 checks")
            else
                error("malformed file (bytes 15:18 should be 0xfef82111 but they are $(repr(check))")
            end
            # The version number is not used except to show it if debug>0
            vmjr = reinterpret(UInt8, buf[offset+19])[1]
            vmnr = reinterpret(UInt8, buf[offset+20])[1]
            oad(debug, "      File is in DT4 format version $vmjr.$vmnr")
        elseif code == 0x001e
            oad(debug, "    V3 file header")
        elseif code == 0x0018
            oad(debug, "    V2 file header")
        elseif code == 0x0001
            oad(debug, "    V1 file header")
        elseif code == 0x0012
            oad(debug, "    Channel Descriptor")
            # From the sample file:
            # number=1 blankedSamples=57 dt=2.4e-05 pingsInFile=780 samplesPerPing=3399
            # number=2 blankedSamples=57 dt=2.4e-05 pingsInFile=780 samplesPerPing=3399
            channel_number = convert(Int64, reinterpret(UInt16, buf[(offset).+(5:6)])[1])
            oad(debug, "      channel $channel")
            # number of pings
            np = convert(Int64, reinterpret(UInt32, buf[(offset).+(7:10)])[1])
            oad(debug, "      np $np")
            spp = convert(Int64, reinterpret(UInt16, buf[(offset).+(11:12)])[1])
            oad(debug, "      spp $spp")
            push!(channels, (channel_number=channel_number, np=np, spp=spp))
            if nrow(channels) > 2
                @warn "Have more than 2 Channel Descriptor entries"
            end
            # Several other things here can be decoded if required
            # FIXME: set aside space for 3 arrays (???) of size np x spp
            a = Matrix{Float64}(undef, np, spp)
            println("a dim: $(size(a))")
        elseif code == 0x0036
            oad(debug, "    Extended Channel Descriptor")
        elseif code == 0x0015
            oad(debug, "    Single-Beam Ping")
            channel_number = reinterpret(UInt8, buf[offset+5])[1]
            oad(debug, "      channel_number: $channel_number")
            ping_number = reinterpret(UInt32, buf[(offset).+(7:10)])[1]
            oad(debug, "      ping_number: $ping_number")
            ptm = reinterpret(UInt32, buf[(offset).+(11:14)])[1]
            oad(debug, "      ptm: $ptm (msec since start)")
            ns = reinterpret(UInt16, buf[(offset).+(15:16)])[1]
            #oad(debug, "      ns: $ns (recall spp: $(channels[!,channel].spp))")
            oad(debug, "      ns: $ns")
            if channel_number == channel
                spp = channels[firstindex(channels.channel_number == channel), :spp]
                println("*** spp=$spp")
            else
                oad(debug, "      ignored, since user specified channel=$channel")
            end
        elseif code == 0x001C
            oad(debug, "    Dual-Beam Ping")
        elseif code == 0x0010
            oad(debug, "    Split-Beam Ping")
        elseif code == 0x000F || code == 0x0020
            # For reference, oce/create_data/echosounder/test_for_julia.R gives:
            # [1] "2008-07-01 16:39:40.900 UTC" "2008-07-01 16:39:41.140 UTC"
            # [3] "2008-07-01 16:39:41.389 UTC" "2008-07-01 16:39:41.630 UTC"
            # [5] "2008-07-01 16:39:41.880 UTC" "2008-07-01 16:39:42.119 UTC"
            oad(debug, "    Time (type 0x000f or 0x0020)")
            seconds = reinterpret(UInt32, buf[(offset).+(5:8)])[1]
            subseconds = 0.01 * reinterpret(UInt8, buf[offset+9])[1]
            last_time = unix2datetime(seconds + subseconds)
            oad(debug, "      last_time: $last_time")
        elseif code == 0x0011
            oad(debug, "    Navigation String")
        elseif code == 0x0030
            oad(debug, "    Timestamped Navigation String")
        elseif code == 0x0031
            oad(debug, "    Transducer Orientation")
        elseif code == 0x0032
            oad(debug, "    Bottom Pick")
        elseif code == 0x0033
            oad(debug, "    Single Echoes")
        elseif code == 0x0034
            oad(debug, "    Comment")
        elseif code == 0xFFFE
            oad(debug, "    End of File")
        else
            oad(debug, "    UNRECOGNIZED CODE $(repr(code))")
        end
        data = buf[range(offset + 4, length=N)]
        N6 = convert(Int64, reinterpret(UInt16, buf[(offset+4+N).+(1:2)])[1])
        N6 == N + 6 || error("tuple does not end correctly")
        offset += 6 + N
        tuple += 1
        if tuples > 0 && tuple > tuples
            break
        end
    end
    rval = 1
    oad(debug, "channels: $channels")
    oad(debug, "END read_echosounder()")
    rval
end
#buf = read(expanduser(filename));
#reinterpret(UInt16, buf[3:4])[1] == 0xffff

