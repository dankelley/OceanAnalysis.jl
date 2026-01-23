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

f = "/Users/kelley/Dropbox/data/archive/sleiwex/2008/fielddata/2008-07-01/Merlu/Biosonics/20080701_163942.dt4"
buf = read(f)
println("read file with $(length(buf)) bytes")
buf = buf[range(7527, length=2 * 3398)];
println("created buf of length $(length(buf))")
spp = 3399
rval = Array{UInt8}(undef, 2 * spp);
dt4_expand_rle!(buf, rval);

N = 12
println("buf (of length $(length(buf))) starts")
println("  ", first(buf, N))
println("rval (of length $(length(rval))) starts")
println("  ", first(rval, N))

println("buf (of length $(length(buf)) )ends")
println("  ", last(buf, N))
println("rval (of length $(length(rval))) ends")
println("  ", last(rval, N))
