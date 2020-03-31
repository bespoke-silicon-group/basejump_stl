make stat_header > stat.csv

traces=("stream_read" "stream_write" "vector_add" "memcpy")

#for trace in ${traces[*]}
#do
  #make clean
  #make TRACE_GEN=$trace
  #make stat >> stat.csv
#done
