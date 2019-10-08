#
#   trace_gen.py
#

import sys
sys.path.append('../common')
from bsg_cache_non_blocking_trace_gen import *


class BsgCacheNonBlockingRegression:
  
  def __init__(self, id_width_p, data_width_p, addr_width_p):
    self.tg = BsgCacheNonBlockingTraceGen(id_width_p,addr_width_p,data_width_p)
    self.curr_id = 0
    self.curr_data = 1
    self.sets_p = 128
    self.ways_p = 8

  def send(self, opcode, addr):
    self.tg.send(self.curr_id, opcode, addr, self.curr_data)
    self.curr_id += 1
    if opcode == SW:
      self.curr_data += 1 

  def clear_tag(self):
    for i in range(self.sets_p*self.ways_p):
      self.send(TAGST, i<<5)

  def wait(self, n):
    self.tg.wait(n)

  def done(self):
    self.tg.done()


#   main()
if __name__ == "__main__":
  id_width_p = 20
  data_width_p = 32
  addr_width_p = 32
  tg = BsgCacheNonBlockingRegression(id_width_p, addr_width_p, data_width_p)
  tg.wait(10)
  tg.clear_tag()
  tg.wait(20)

  for i in range(16):
    tg.send(SW, i<<2)
    
  for i in range(16):
    tg.send(LW, i<<2)


  # done
  tg.wait(500)
  tg.done()


