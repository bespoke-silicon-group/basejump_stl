
traces=("stream_read" "stream_write" "vector_add" "memcpy" "const_random" "full_random" \
        "const_random_read" "stride_read_16" "stride_read_32" "stride_read_64")
block_sizes=(8 16 32 64)
dma_data_widths=(32 64)

make stat_header > stat.csv

for block_size in ${block_sizes[*]}
do
  for dma_data_width in ${dma_data_widths[*]}
  do
    # rebuild
    make clean
    make simv BLOCK_SIZE_IN_WORDS_P=$block_size DMA_DATA_WIDTH_P=$dma_data_width

    # run in parallel
    for trace in ${traces[*]}
    do
      make run TRACE_GEN=$trace &
    done
    wait

    # gather stat
    for trace in ${traces[*]}
    do
      make stat TRACE_GEN=$trace >> stat.csv
    done

  done
done


