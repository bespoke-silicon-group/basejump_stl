#!/bin/bash

rm -rf test_result.log
echo "start test" > test_result.log
run_test() {
  make clean
  make -j2  BLOCK_SIZE_IN_WORDS_P=$1
  echo "################" >> test_result.log
  echo $1  >> test_result.log
  make summary >> test_result.log
}

run_test 8
run_test 4
run_test 2
run_test 1

if grep -H --color -e "BSG_FATAL" -e "Error" -e "BSG_ERROR" test_result.log; then
  echo test failed.
else
  echo test successful.
fi