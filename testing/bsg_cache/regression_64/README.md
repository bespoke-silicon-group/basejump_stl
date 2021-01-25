The tests in regression_64 cover all 4 data_width_p and block_size_in_words_p configurations of bsg_cache used in Black Parrot. And the configurations are listed in the following table.

```
cache_block_width_p  |  data_width_p   |  block_size_in_words_p
                            64                 8
      512                  128                 4
                           256                 2
                           512                 1
```

Default configuration is `data_width_p == 64, block_size_in_words_p == 8`. To switch between different configurations, just change `BLOCK_SIZE_IN_WORDS_P` in Makefile, then `data_width_p` is calculated by `512/BLOCK_SIZE_IN_WORDS_P` in the testbench and trace scripts. To run all tests with the designated configuration, suimply run
```
make clean all summary
```

In addition, a bash script, width_sweep.sh is added to run regression test over all the configurations in the above table. To run regression test, simply run 
```
./width_sweep.sh
```
And the result is stored in the test_result.log, and is labeled with corresponding block_size_in_words_p in each section.

