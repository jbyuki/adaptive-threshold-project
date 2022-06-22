Adaptive threshold mini-project
===============================

Benchmarks
----------

```
1’484 µs  -   FPGA @ 50 MHz
156 µs    -   Intel i7-8650U @ 1.90 GHz (opencv-python)
```

Still slower than my laptop but not bad considering that the optimal speed for the FGPA is around 700 µs.

Possible speed-ups
------------------

* Bigger bus width on the F2H bridge (32bits -> 128bits) , 4x speedup
* Increase FPGA clock (50MHz -> 200MHz), 4x speedup
* Multiple accelerators working in parallel, Nx speedup
