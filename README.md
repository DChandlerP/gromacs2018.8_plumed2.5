# Gromacs

### Benchmarking & Testing

[Max Plank Institute offers several benchmark options](https://www.mpibpc.mpg.de/grubmueller/bench) and provides instructions on how to run them.
These will likely be different than what the work a researcher does, but it's important to have a benchmark that runs in 
tens of seconds or several minutes and not hours or days to get fast feedback. 

* The following benchmark has been chosen for consistency [benchmark](https://www.mpibpc.mpg.de/15615646/benchPEP.zip): 
* Note results. 2018.8 seems to yield more variable results than later versions, so consider averaging a few results.

## Engineering Docs


### FFTW

`libfftw3-dev` Experimenting with different Gromacs options found that this library used in the Whitelab image
is significantly faster than what Gromacs was using with this flag `-DGMX_BUILD_OWN_FFTW=ON`. This is the opposite
of what the Gromacs manual option recommends.

### Docker Build is Dependent on the CPUs used to compile it with.  (SIMD Support)

The SIMD Support section discusses this in more depth. Gromacs detects what chips you're using and optimizes Gromacs accordingly.
With 2018.8 it often looked like selecting [AVX-512](https://en.wikichip.org/wiki/x86/avx-512) was giving us 256 based on output visible during the installation. 
Based on the [release notes for each version](http://manual.gromacs.org/), it looks as if later
versions are better optimized for AVX-512. The installation page for more recent versions mention the flags one can use
to indicate what architecture you'd like to optimize for in this [Simd support section of the installation page](http://manual.gromacs.org/current/install-guide/index.html).
According to the documentation, you can override Gromacs SIMD detection with the SIMD flags.

### HWLOC

Versions greater than 2018.8 are compatible with a newer version of [hwloc](https://www.open-mpi.org/projects/hwloc/). 
With 2018.8 you should use an older Linux OS in order to get the older hwloc package. It appears that the older hwloc has reduced
performance from benchmark tests. 

### Not Optimized for GPUS

In general, I'd recommend using NVIDIA's image and use GPUs for the best performance. This was build for a specific request for an image
without GPUs. Granted, the benefit of using GPUs is likely specific to your specific use case.

### Whitelab plumed-gromacs Dockerfile

This image served as the basis of work on the Dockerfile we've customized:
https://hub.docker.com/r/whitelab/plumed-gromacs










