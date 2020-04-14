import sys
from trace_gen import *

if __name__ == "__main__":
  num_cache_p = int(sys.argv[1])
  block_size_in_words_p = int(sys.argv[2])

  tg = TraceGen(block_size_in_words_p)
  tg.clear_tags()

  words = (2**18)/num_cache_p # 1MB
  #words = (2**20)/num_cache_p # 2MB
  #words = 512/num_cache_p # 2KB (one page)
  for i in range(words):
    tg.send_read(i<<2)

  tg.done()
