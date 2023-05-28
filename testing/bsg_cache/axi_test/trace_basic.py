
import sys
sys.path.append('../common')
from bsg_cache_dma_trace_gen import *


#   main()
if __name__ == "__main__":
  block_width_p = 32
  data_width_p  = 8
  addr_width_p  = 5
  tg = BsgCacheDmaTraceGen(addr_width_p, data_width_p, block_width_p)

  # Test aligned access
  tg.send_write(0, 0x03020100)
  tg.send_read(0, 0x03020100)
  tg.send_write(4, 0x07060504)
  tg.send_read(4, 0x07060504)

  tg.send_read(1, 0x00030201)

  # Test read/write ordering
  tg.send_write(0, 0xbeefbeef)
  tg.send_read(0, 0xbeefbeef)
  tg.send_write(0, 0x0deaddead)
  tg.send_read(0, 0x0deaddead)

  tg.done()

