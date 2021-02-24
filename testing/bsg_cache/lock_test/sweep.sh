#!/bin/bash

rm -rf test_result.log
echo "start test" > test_result.log
run_test() {
  make clean
  echo "################" >> test_result.log
  if [ $2 == test_lock_multiway ]
    then
      echo WAY_ON_LOCKED_P = $1  `expr $1 + 1` >> test_result.log
    else
      echo WAY_ON_LOCKED_P = $1  >> test_result.log
  fi
  make $2.basic.run WAY_ON_LOCKED_P=$1
  make $2.summary >> test_result.log
}

echo "################################################################" >> test_result.log
echo "                        Running test_lock1 ...                  " >> test_result.log
echo "################################################################" >> test_result.log
for ((locked_way = 0; locked_way < 8; locked_way++));  
  do   
    for((i = 0; i < 5; i++));  
      do  
        run_test $locked_way test_lock1;
      done 
  done 

echo "################################################################" >> test_result.log
echo "                        Running test_lock2 ...                  " >> test_result.log
echo "################################################################" >> test_result.log
for ((locked_way = 0; locked_way < 8; locked_way++));  
  do   
    for((i = 0; i < 5; i++));  
      do   
        run_test $locked_way test_lock2
      done 
  done 

echo "################################################################" >> test_result.log
echo "                   Running test_lock_multiway ...               " >> test_result.log
echo "################################################################" >> test_result.log
for ((locked_way = 0; locked_way < 7; locked_way++));  
  do   
    for((i = 0; i < 5; i++));  
      do
        run_test $locked_way test_lock_multiway;
      done 
  done 

if grep -H --color -e "BSG_FATAL" -e "Error" -e "BSG_ERROR" test_result.log; then
  echo test failed.
else
  echo test successful.
fi