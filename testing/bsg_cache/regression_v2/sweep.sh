#!/bin/bash

echo "start test" > test_result.log
run_test() {
  export YUMI_MIN_DELAY_P  = $1
  export YUMI_MAX_DELAY_P  = $2
  export DMA_READ_DELAY_P  = $3
  export DMA_WRITE_DELAY_P = $4
  export DMA_REQ_DELAY_P   = $5
  export DMA_DATA_DELAY_P  = $6
  make clean
  make -j8
  echo "################" >> test_result.log
  echo $1 $2 $3 $4 $5 $6 >> test_result.log
  make summary >> test_result.log
}

run_test 0 0 0 0 0 0
run_test 0 2 0 0 0 0
run_test 0 4 0 0 0 0

run_test 0 0 16 16 4 4
run_test 0 2 16 16 4 4
run_test 0 4 16 16 4 4

if grep -H --color -e "BSG_FATAL" -e "Error" -e "BSG_ERROR" test_result.log; then
  echo test failed.
else
  echo test successful.
fi
