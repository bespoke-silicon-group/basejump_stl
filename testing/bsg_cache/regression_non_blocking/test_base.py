import sys
import random
sys.path.append('../common')
from bsg_cache_non_blocking_trace_gen import *

class TestBase:
  
  MAX_ADDR = (2**17)

  # default constructor
  def __init__(self):
    id_width_p = 30
    data_width_p = 32
    addr_width_p = 32
    self.tg = BsgCacheNonBlockingTraceGen(id_width_p,addr_width_p,data_width_p)
    self.curr_id = 0
    self.curr_data = 1
    self.sets_p = 128
    self.ways_p = 8
    self.block_size_in_words_p = 8

  def send(self, opcode, addr, mask=0):
    if opcode == SW or opcode == SH or opcode == SB:
      self.tg.send(self.curr_id, opcode, addr, self.curr_data)
      self.curr_data += 1 
    elif opcode == SM:
      self.tg.send(self.curr_id, opcode, addr, self.curr_data, mask)
      self.curr_data += 1 
    elif opcode == LW or opcode == LH or opcode == LB or opcode == LHU or opcode == LBU:
      self.tg.send(self.curr_id, opcode, addr)
    elif opcode == TAGST or opcode == TAGFL or opcode == AFL:
      self.tg.send(self.curr_id, opcode, addr, data=0)
    self.curr_id += 1

  def clear_tag(self):
    for i in range(self.sets_p * self.ways_p):
      self.send(TAGST, i<<5)

  def flush_inv(self, way, index):
    addr = self.get_addr(way, index)
    self.send(TAGFL, addr)
    self.send(TAGST, addr)

  def get_addr(self, tag, index, block_offset=0, byte_offset=0):
    addr = tag << 12
    addr += index << 5
    addr += block_offset << 2
    addr += byte_offset
    return addr 

  def wait(self, n):
    if n == 1:
      self.tg.nop()
    else:
      self.tg.wait(n)

  def done(self):
    self.tg.done()

  # max_delay: max delay in number of cycle
  def delay_random(self, max_delay):
    delay = random.randint(0,max_delay)
    if delay != 0:
      self.wait(delay)
