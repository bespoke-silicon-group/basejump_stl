import sys
from trace_gen import *

if __name__ == "__main__":

  num_cache_group_p = int(sys.argv[1])
  num_subcache_p = int(sys.argv[2])
  block_size_in_words_p = int(sys.argv[3])

  tg = TraceGen(num_subcache_p, block_size_in_words_p)
  tg.clear_tags()

  words = (2**18)/num_cache_group_p # 1MB
  #words = (2**20)/num_cache_p # 2MB
  #words = 512/num_cache_p # 2KB (one page)
  for i in range(words):
    tg.send_write(i<<2)

  tg.done()
