#
#   dmc_trace_gen.py
#

import sys
import time
import random
sys.path.append('../common')
from bsg_cache_trace_gen import *


#  main()
if __name__ == "__main__":
  tg = BsgCacheTraceGen(addr_width_p=27, data_width_p=32)
  sets_p = 512
  ways_p = int(sys.argv[2])
  id_p = int(sys.argv[1])
  random.seed(time.time())
  
  mem_dict = {}
  store_val = id_p 
 
  # clear tags 
  for i in range(sets_p*ways_p):
    tg.send(TAGST, (i<<(3+2)), 0)
    tg.recv(0)

  for i in range(20000):
    addr = (random.randint(0, 2**22) << 5)
    delay = random.randint(0,100)
     
    if delay == 0:
      pass
    elif delay == 1:
      tg.nop()
    else:
      tg.wait(delay)


    if addr in mem_dict:
      load_not_store = random.randint(0,1)
      if load_not_store == 1:
        tg.send(LW, addr)
        tg.recv(mem_dict[addr])
      else:
        tg.send(SW, addr, store_val)
        tg.recv(0)
        mem_dict[addr] = store_val
        store_val += 4
    else:
      tg.send(SW, addr, store_val)
      tg.recv(0)
      mem_dict[addr] = store_val
      store_val += 4


  # read back everything
  for tu in mem_dict.items():
    delay = random.randint(0,32)
     
    if delay == 0:
      pass
    elif delay == 1:
      tg.nop()
    else:
      tg.wait(delay)

    tg.send(LW, tu[0])
    tg.recv(tu[1])  

  # done
  tg.done()
