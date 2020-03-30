import sys
from trace_gen import *

if __name__ == "__main__":
  # common parameters
  id_p = int(sys.argv[1])
  num_cache_group_p = int(sys.argv[2])
  num_subcache_p = int(sys.argv[3])
  block_size_in_words_p = int(sys.argv[4])

  tg = TraceGen(num_subcache_p, block_size_in_words_p)
  tg.clear_tags()

  words = (2**18)/num_cache_group_p # 1MB
  #words = (2**9)/num_cache_group_p # 2KB
  for i in range(words):
    tg.send_read(i<<2)

  tg.done()
