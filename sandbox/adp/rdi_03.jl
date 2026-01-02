file = "/Users/kelley/data/archive/sleiwex/2008/moorings/m09/adp/rdi_2615/raw/adp_rdi_2615.000"
file = "adp_rdi.000"
buf = read(file);
nbuf = length(buf)
start = 1
while true # Find first 7f 7f byte pair, in case file starts mid-chunk
    if buf[start] == 0x7f & buf[start+1] == 0x7f
        break
    end
    global start += 1
    if start >= nbuf - 1
        error("no 0x7f 0x74 in file $file")
    end
end
starts = Vector{Int64}()
for chunk in 1:40
    global start
    if start >= nbuf # got to end of buffer before 
        println("EOF encountered after chunk $(chunk-1)")
        break
    end
    # Do next manually, since (I think) Julia obeys OS endianness
    #> bytes_to_check = Int16(reinterpret(UInt16, buf[2:3])[1])
    local bytes_to_check = buf[start+2] + 256 * buf[start+3]
    println("chunk $chunk, start $start, bytes_to_check $bytes_to_check")
    local bytes_to_read = bytes_to_check - 4
    local checksum::UInt16 = 0
    for i in range(start, length=bytes_to_check)
        checksum += buf[i] # relies on overflow wrapping around zero
    end
    local desired_checksum = buf[start+bytes_to_check] + 256 * buf[start+bytes_to_check+1]
    if checksum == desired_checksum
        push!(starts, start)
    else
        println("  bad checksum=$checksum (desired_checksum=$desired_checksum)")
    end
    start += bytes_to_check + 2
end
println(starts)
