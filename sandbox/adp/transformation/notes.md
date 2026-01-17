# 03.jl time to read 138M RDI file

* Predict about 7s for a 1G RDI file.
* R (03_R.R) takes 4.8s, so Julia is about 10X faster than R.

```
  1.683399 seconds (16.32 M allocations: 1.426 GiB, 21.17% gc time, 56.46% compilation time)
  0.724905 seconds (9.01 M allocations: 1.075 GiB, 39.00% gc time)
  0.575073 seconds (9.01 M allocations: 1.075 GiB, 25.45% gc time)
  0.565340 seconds (9.01 M allocations: 1.075 GiB, 26.46% gc time)
  0.560606 seconds (9.01 M allocations: 1.075 GiB, 26.59% gc time)
  0.568134 seconds (9.01 M allocations: 1.075 GiB, 26.61% gc time)
```

# 04.jl time to convert 138M RDI file from beam to xyz

* R (04_R.R) takes 0.4s, so Julia is nearly 2X as fast as R.
* Predict about 3s for a 1G RDI file.
* FIXME can halve time and 1/10th alloc but get wrong ans

## Method 1: loop on ensemble

```
  0.361595 seconds (1.80 M allocations: 720.544 MiB, 42.14% gc time, 24.38% compilation time)
  0.255215 seconds (1.34 M allocations: 697.901 MiB, 56.25% gc time)
  0.256720 seconds (1.34 M allocations: 697.901 MiB, 57.25% gc time)
  0.115706 seconds (1.34 M allocations: 697.901 MiB, 15.56% gc time)
  0.240422 seconds (1.34 M allocations: 697.901 MiB, 54.69% gc time)
```

## Method 2: three lines of code, as R/oce

This is a bit under 10% faster than first trial, but it allocates nearly 3X
more memory. I think that in the end the memory cost must be the same as the
first method, but at least temporarily, method 2 puts more pressure on the
system.  And we may have files 10X this large, and that could be more memory
than the machine has. Therefore I am retaining method 1 in the code and putting
method 2 in a commented-out portion.

```
  0.534988 seconds (930.53 k allocations: 1.827 GiB, 52.16% gc time, 30.16% compilation time)
  0.207432 seconds (195 allocations: 1.783 GiB, 65.91% gc time)
  0.201997 seconds (195 allocations: 1.783 GiB, 67.07% gc time)
  0.199406 seconds (195 allocations: 1.783 GiB, 67.28% gc time)
  0.189983 seconds (195 allocations: 1.783 GiB, 70.14% gc time)
```
