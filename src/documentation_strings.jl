DEBUG_TEMPLATE = """
- `debug` an integer indicating whether to print information during
  processing. The default value of 0 means to work quietly, and any
  larger integer indicates to print some information, with higher
  values of `debug` resulting in wider indentation of the material.
  Functions that call other functions in the package generally
  increase `debug` by calling [`increment_debug`](@ref).
"""
