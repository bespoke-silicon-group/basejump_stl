#!/bin/bash
rm -r aalloc_measure_result.log
echo "start test" > aalloc_measure_result.log
run_test() {
  make clean
  make -j3 aalloc_perf_meas GET_MISS_STATS_P=1
                            YUMI_MIN_DELAY_P=$1  \
                            YUMI_MAX_DELAY_P=$2  \
                            DMA_READ_DELAY_P=$3  \
                            DMA_WRITE_DELAY_P=$4 \
                            DMA_REQ_DELAY_P=$5   \
                            DMA_DATA_DELAY_P=$6
  echo "################" >> aalloc_measure_result.log
  echo $1 $2 $3 $4 $5 $6 >> aalloc_measure_result.log
  make aalloc_perf_summary >> aalloc_measure_result.log
}

run_test 0 0 0 0 0 0
run_test 0 2 0 0 0 0
run_test 0 4 0 0 0 0

run_test 0 0 16 16 4 4
run_test 0 2 16 16 4 4
run_test 0 4 16 16 4 4

if grep -H --color -e "BSG_FATAL" -e "Error" -e "BSG_ERROR" aalloc_measure_result.log; then
  echo test failed.
else
  echo test successful.
fi


