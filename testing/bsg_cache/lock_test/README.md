These tests aim at detecting LRU way allocating issues when one or more ways are locked. 

A new test module, `lru_stats` is added. This module binds with `bsg_cache_miss` and records its each replecement choice. Correspondingly, 4 test trace scripts, test_lock1, test_lock2, test_lock_multiway and test_lock_multiset  are added.

1. test_lock1: This test simulate the real time opperating system where we want to lock a specific line in the cache for a certain time response in the run time. In this case, ALOCK op is used to lock the block and also update the LRU info. An it is allowed to load/store the locked block after it is on locked. All the accessed cache lines are at the index 0.
2. test_lock2: This test simulate the case that we want to abort a specific way at a specific index due to fabrication defects on the SRAM block. TAGST op is used at initialized and the locked way is never accessed. All the accessed cache lines are at the index 0.
3. test_lock_multiway: This is a variation of test_lock2 where 2 conescutive ways of index 0 are locked.
4. test_lock_multiset: This is a variation of test_lock2 where all set are accessed rather than a single set.

All these 4 tests have 2 different work modes. 

- Always missed mode (default): Access 32 blocks with tags from 0 to 31 at a set sequentially, so that there is always a cache miss and LRU updates are handled by the bsg_cache_miss. This is a special case because we want to spot the issue among the current replacement strategy.
- Random access mode: Randomly access 32 blocks with tags from 0 to 31 at a set. LRU can also updated by load/store hit, so it is more like a general senario.

After each test is finished, `lru_stats` display how many times each way is chosen by the LRU replcement strategy.

The locked way is designated in the Makefile with the parameter, `WAY_ON_LOCKED_P`. 

And a shell script, sweep.sh is added, which runs both test_lock1, test_lock2 and test_lock_multiway for multiple times with different ways on locked. There are 2 parameters, ways_p which is identical with the one in the testbench, and sample_cnt_p which determines the number sample points for each locking pattern, in the script. To run this regression, simply run 
```
$ ./sweep.sh
```