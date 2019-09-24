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
    self.block_size_in_words_p = 8

  def send(self, opcode, addr):
    if opcode == SW:
      self.tg.send(self.curr_id, SW, addr, self.curr_data)
      self.curr_data += 1 
    elif opcode == LW:
      self.tg.send(self.curr_id, LW, addr)
    elif opcode == BLOCK_LD:
      self.tg.send(self.curr_id, BLOCK_LD, addr)
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

  # max_delay: max delay in number of cycle
  def delay_random(self, max_delay):
    delay = random.randint(0,max_delay)
    if delay != 0:
      self.wait(delay)


  def block_store(self, block_addr):
    base_addr = block_addr - (block_addr % (self.block_size_in_words_p*4))
    for i in range(0,self.block_size_in_words_p*4,4):
      self.send(SW, base_addr+i)
      
  def block_load(self, block_addr):
    base_addr = block_addr - (block_addr % (self.block_size_in_words_p*4))
    self.send(BLOCK_LD, base_addr)
      
      


#   main()
if __name__ == "__main__":
  id_width_p = 30
  data_width_p = 32
  addr_width_p = 32
  tg = BsgCacheNonBlockingRegression(id_width_p, addr_width_p, data_width_p)

  tg.wait(10)
  tg.clear_tag()

  MAX_ADDR = 65536

  for i in range(0,MAX_ADDR,32):
    tg.block_store(i)
    tg.block_load(i)

  for i in range(1000000):
    load_not_store = random.randint(0,1)
    addr = random.randint(0,MAX_ADDR-1)
    if load_not_store: 
      tg.block_load(addr)
    else:
      tg.block_store(addr)
    

  # done
  tg.done()


