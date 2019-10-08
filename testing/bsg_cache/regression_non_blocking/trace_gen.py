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

  # stride: byte size
  # max_addr: exclusive upper bound for addr.
  def test_stride(self, stride, max_addr):
    base = 0
    while base < stride:
      i = base
      while i < max_addr:
        self.send(SW, i)
        i += stride
      i = base
      while i < max_addr:
        self.send(LW, i)
        i += stride
      base += 4


#   main()
if __name__ == "__main__":
  id_width_p = 20
  data_width_p = 32
  addr_width_p = 32
  tg = BsgCacheNonBlockingRegression(id_width_p, addr_width_p, data_width_p)

  tg.wait(10)
  tg.clear_tag()

  MAX_ADDR = 65536
  tg.test_stride(4, MAX_ADDR)
  tg.test_stride(8, MAX_ADDR)
  tg.test_stride(12, MAX_ADDR)
  tg.test_stride(16, MAX_ADDR)
  tg.test_stride(20, MAX_ADDR)
  tg.test_stride(24, MAX_ADDR)
  tg.test_stride(28, MAX_ADDR)
  tg.test_stride(32, MAX_ADDR)
  tg.test_stride(36, MAX_ADDR)
  tg.test_stride(40, MAX_ADDR)
  tg.test_stride(44, MAX_ADDR)
  tg.test_stride(48, MAX_ADDR)
  tg.test_stride(52, MAX_ADDR)
  tg.test_stride(56, MAX_ADDR)
  tg.test_stride(60, MAX_ADDR)
  tg.test_stride(64, MAX_ADDR)
  tg.test_stride(68, MAX_ADDR)
  tg.test_stride(72, MAX_ADDR)
  tg.test_stride(76, MAX_ADDR)
  tg.test_stride(80, MAX_ADDR)

  # done
  tg.done()


