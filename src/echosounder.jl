"""
    read_echosounder(filename::String; tuples::Int64=0, debug=0)

Read data from a Biosonics scientific echosounder

# Examples
```julia
# This test will only work if a particular file exists
using OceanAnalysis
filename = "/Users/kelley/Dropbox/data/archive/sleiwex/2008/fielddata/2008-07-01/Merlu/Biosonics/20080701_163942.dt4"
if isfile(filename)
    e = read_echosounder(filename; debug=1);
end
```
"""
function read_echosounder(filename::String; tuples::Int64=0, debug=0)
    oad(debug, "read_echosounder() START")
    filename = expanduser(filename)
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
            ns = reinterpret(UInt16, buf[(offset).+(15:16)])[1]
            oad(debug, "      ns: $ns")
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

