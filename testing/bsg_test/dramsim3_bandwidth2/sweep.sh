make stat_header > stat.csv

traces=("stream_read" "stream_write" "vector_add" "memcpy")

make clean
make simv

for trace in ${traces[*]}
do
  make run TRACE_GEN=$trace &
done
wait

for trace in ${traces[*]}
do
  make stat TRACE_GEN=$trace >> stat.csv
done
