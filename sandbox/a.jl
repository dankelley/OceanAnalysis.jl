a = function (x=nothing)
    if isnothing(x)
        println(" you have me nuthing, dood")
    else
        println("yay! x=$x")
    end
end
a()
a("dan")
a(1.0)
a([1 2 3])
a([1; 2; 3])
a([1.0; 2.0; 3.0])
