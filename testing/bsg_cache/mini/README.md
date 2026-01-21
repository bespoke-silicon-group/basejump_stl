```
regression test on bsg_cache with notification turned on, 
testing the basic functionalities, io operation correctness 
and cache coherence

- Run "make simv" to compile simulation program.
  - add "WAVE=1" to generate waveform.
- Run "make" to run. Add -j16 to run 16 threads in parallel.
- Run "make clean" to delete all outputs.
- Run "make {test_name_py}.dve" to open waveform.
- Run "make cov" to open coverage report.
- Run "make summary" to see the testing results

basic_checker_32 will check the correctness of dram read/write
and uncached(io) read/write, tag_mem_check will check the cache
coherence by comparing the shadow tag directory and tag memories.
After running all the test and "make summary", we expect that for
each testing suite there should be a "TEST SUCCESSFULLY".
```