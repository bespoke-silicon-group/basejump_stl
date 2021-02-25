#!/bin/bash

rm -rf test_result.log
make clean
echo "start test" > test_result.log
run_test() {
  ways_p=8 
  sample_cnt_p=3 

  for ((locked_way=0; locked_way<$ways_p; locked_way++));  
    do   
      for((iter=0; iter<$sample_cnt_p; iter++));  
        do  
          make $1.trace_clean
          if [ $1 == test_lock_multiway ]
            then
              locked_way_plus1=`expr $locked_way + 1`
              echo "######### Running" $1 WAY_ON_LOCKED_P = $locked_way  `expr $locked_way_plus1 % $ways_p` "#########">> test_result.log
            else
              echo "######### Running" $1 WAY_ON_LOCKED_P = $locked_way  "#########" >> test_result.log
          fi
          make $1.basic.run WAY_ON_LOCKED_P=$locked_way
          make $1.summary >> test_result.log
        done 
    done
}
export -f run_test

run_test test_lock1
run_test test_lock2
run_test test_lock_multiway

if grep -H --color -e "BSG_FATAL" -e "Error" -e "BSG_ERROR" test_result.log; then
  echo test failed.
else
  echo test successful.
fi