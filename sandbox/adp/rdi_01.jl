function build_with_hint(N::Int)
    x = Vector{Int}()
    sizehint!(x, N) # Hint the capacity
    for n = 1:N
        push!(x, n)
    end
    return x
end

for N in [100; 100; 1000; 10000; 100000; 1000000; 10000000]
    println("log10(N): $(log10(N))")
    @time x = build_with_hint(N)
end

