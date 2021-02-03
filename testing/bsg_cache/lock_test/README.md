These tests aim at detecting LRU way allocating issues when one or more ways are locked. 

The first test, test_lock1 randomly locks one of n ways in set 0, then implements intensive load/store on the same sets with 16 different tags. The way to be locked can also be desinated by changing the variable, `way_to_lock`, then the `way_to_lock` way will be locked.

The second test, test_lock2 locks the 0-th way of each set, then implements intensive load/store on all sets with 16 different tags.

After each test is finished, module `lru_stats` display how many times each way is chosen by the LRU replcement strategy.