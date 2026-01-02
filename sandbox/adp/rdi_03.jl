file = "/Users/kelley/data/archive/sleiwex/2008/moorings/m09/adp/rdi_2615/raw/adp_rdi_2615.000"
#file = "adp_rdi.000"
buf = read(file);
nbuf = length(buf)
offset = 0
while true
    if buf[offset+1] == 0x7f & buf[offset+2] == 0x7f
        break
    end
    global offset += 1
    if offset >= nbuf - 1
        error("no 0x7f 0x74 in file $file")
    end
end
offset = 1 # NB oce/C code uses 0, since C is zero-indexed
for chunk in 1:100
    global offset
    # Do the conversion manually (as in C within oce) to avoid
    # problems if done in a big-endian context.
    #> bytes_to_check = Int16(reinterpret(UInt16, buf[3:4])[1])
    local bytes_to_check = buf[offset+2] + 256 * buf[offset+3]
    println("chunk $chunk, offset $offset, bytes_to_check $bytes_to_check")
    local bytes_to_read = bytes_to_check - 4
    local checksum::UInt16 = 0
    for i in range(offset, length=bytes_to_check)
        checksum += buf[i]
    end
    local c1 = buf[offset+bytes_to_check]
    local c2 = buf[offset+bytes_to_check+1]
    local desired_checksum = c1 + 256 * c2
    if checksum == desired_checksum
        println("  good checksum=$checksum")
    else
        println("  bad checksum=$checksum (desired_checksum=$desired_checksum)")
    end
    offset += bytes_to_check + 2
end

#bytes_to_check = (unsigned int)b1 + 256 * (unsigned int)b2;

#io = IOBuffer([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]); # 8 bytes
## Read into a Vector{Int16}
#array = zeros(Int16, 4) # Pre-allocate array of 4 Int16s (8 bytes total)
#read!(io, array)
#size(io)
#buf = read("adp_rdi.000");
#io = IOBuffer([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]); # 8 bytes
## Read into a Vector{Int16}
#array = zeros(Int16, 4) # Pre-allocate array of 4 Int16s (8 bytes total)
#read!(io, array)
#size(io)
#buf = read("adp_rdi.000");
