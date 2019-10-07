#
#   trace_gen.py
#

import sys
sys.path.append('../common')
from bsg_cache_non_blocking_trace_gen import *




#   main()
if __name__ == "__main__":
  id_width_p = 20
  data_width_p = 32
  addr_width_p = 32
  tg = BsgCacheNonBlockingTraceGen(id_width_p, addr_width_p, data_width_p)

  curr_id = 0
  curr_data = 1

  # clear tags
  tg.nop()
  tg.nop()
  for i in range(8):
    tg.send(curr_id, TAGST, i << 12, 0)
    curr_id += 1

  # store and load
  tg.send(curr_id, SW, 0, curr_data)
  curr_id += 1
  curr_data += 1
  tg.send(curr_id, LW, 0)
  curr_id += 1

  # done
  tg.wait(500)
  tg.done()


