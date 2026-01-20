using OceanAnalysis

function oad(debug, msg...)
    if (debug > 0)
        println(msg...)
    end
end

function read_echosounder(filename::String; tuples::Int64=0, debug=0)
    oad(debug, "read_echosounder() START")
    filename = expanduser(filename)
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
        elseif code == 0x001e
            oad(debug, "    V3 file header")
        elseif code == 0x0018
            oad(debug, "    V2 file header")
        elseif code == 0x0001
            oad(debug, "    V1 file header")
        elseif code == 0x0012
            oad(debug, "    Channel Descriptor")
        elseif code == 0x0036
            oad(debug, "    Extended Channel Descriptor")
        elseif code == 0x0015
            oad(debug, "    Single-Beam Ping")
        elseif code == 0x001C
            oad(debug, "    Dual-Beam Ping")
        elseif code == 0x0010
            oad(debug, "    Split-Beam Ping")
        elseif code == 0x000F
            oad(debug, "    Time (type 0x0F)")
        elseif code == 0x0020
            oad(debug, "    Time (type 0x20)")
        elseif code == 0x000E
            oad(debug, "    Position")
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
    oad(debug, "END read_echosounder()")
    rval
end
filename = "~/Dropbox/data/archive/sleiwex/2008/fielddata/2008-07-01/Merlu/Biosonics/20080701_163942.dt4"
e = read_echosounder(filename; debug=1);
#e = read_echosounder(filename; tuples=0, debug=1);
#buf = read(expanduser(filename));
#reinterpret(UInt16, buf[3:4])[1] == 0xffff

