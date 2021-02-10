#!/bin/bash

rm -rf test_result.log
echo "start test" > test_result.log
run_test() {
  make clean
  echo "################" >> test_result.log
  echo WAY_ON_LOCKED_P = $1  >> test_result.log
  if [ $2 == 0 ]
    then
      make test_lock1.basic.run WAY_ON_LOCKED_P=$1
    else
      make test_lock2.basic.run WAY_ON_LOCKED_P=$1
  fi
  make summary >> test_result.log
}

echo "################################################################" >> test_result.log
echo "                        Running test_lock1 ...                  " >> test_result.log
echo "################################################################" >> test_result.log
test_type = 0;
for ((locked_way = 0; locked_way < 8; locked_way++));  
  do   
    for((i = 0; i < 5; i++));  
      do   
        run_test $locked_way 0; 
      done 
  done 

echo "################################################################" >> test_result.log
echo "                        Running test_lock2 ...                  " >> test_result.log
echo "################################################################" >> test_result.log
test_type = 1;
for ((locked_way = 0; locked_way < 8; locked_way++));  
  do   
    for((i = 0; i < 5; i++));  
      do   
        run_test $locked_way 1; 
      done 
  done 

if grep -H --color -e "BSG_FATAL" -e "Error" -e "BSG_ERROR" test_result.log; then
  echo test failed.
else
  echo test successful.
fi