#
#   trace_gen.py
#

import sys
import random
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
    if opcode == SW:
      self.tg.send(self.curr_id, SW, addr, self.curr_data)
      self.curr_data += 1 
    elif opcode == LW:
      self.tg.send(self.curr_id, LW, addr)
    elif opcode == TAGST:
      self.tg.send(self.curr_id, TAGST, addr)
    self.curr_id += 1

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

  # num: number of random accesses
  # max_addr: exclusive upper bound for addr.
  def test_random(self, num, max_addr):
    for i in range(num):
      addr = random.randint(0, (max_addr/4)-1)*4
      store_not_load = random.randint(0,1)
      if store_not_load:
        self.send(SW, addr)
      else:
        self.send(LW, addr)


#   main()
if __name__ == "__main__":
  id_width_p = 30
  data_width_p = 32
  addr_width_p = 32
  tg = BsgCacheNonBlockingRegression(id_width_p, addr_width_p, data_width_p)

  tg.wait(10)
  tg.clear_tag()

  MAX_ADDR = 65536

  # test_stride
  stride = 4
  while stride < 256:
    tg.test_stride(stride, MAX_ADDR)
    stride += 4

  # test_random
  N = 10000
  tg.test_random(N, MAX_ADDR)


  # done
  tg.done()


