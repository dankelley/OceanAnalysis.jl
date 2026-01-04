# Files

## 01.jl

* Create a large vector with initial size hint
* With 1e7 entries: 0.046691 seconds (3 allocations: 76.297 MiB, 71.94% gc time)

## 02.jl

* As 01.jl but no size hint
* With 1e7 entries: 0.059204 seconds (39 allocations: 235.155 MiB, 61.91% gc time)
* This is only 20% faster than preallocating
* Conclude: at 1e2 to 1e3 bytes per RDI ensemble, a 1Gb file holds 1e6 to 1e7
  entries. Estimate: 1Gb file in 1/20 second.

## 03.jl

* Find chunk starting indices (non-function code -- easier to trace)

## 04.jl

* Find chunk starting indices (function-based code).  Look into headers (maybe
  1/4 way done with that).

## 05.jl

* As 04.jl but now read ensemble_number and time (not in a function yet)

## 06.jl

* As 05.jl but read sound_speed, pitch, heading and roll.
* IMPORTANTLY, add a function to convert two-byte sequences to integers.
* Read 1st ensemble v (and check) ... need to figure out about storage (all in a Dict?)
* Maybe store data as 3D array, forcing user to say which field they want

## 07.jl

* As 06.jl but read a bit more and, finally, do it as a function.
* More tasks:
    * test times
    * do more metadata
    * only get storage if data exist
    * is it acceptably fast? run twice -- is second faster?
