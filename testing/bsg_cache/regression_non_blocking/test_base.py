import sys
import random
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
    elif opcode == AFL:
      self.tg.send(self.curr_id, opcode, addr, data=0)
    else:
      raise Exception("don't do this here.")
    self.curr_id += 1

  
  # TAGST
  def send_tagst(self, way, index, valid=0, lock=0, tag=0):
    addr = self.get_addr(way, index)
    data = (valid << 31) + (lock << 30) + tag
    self.tg.send(self.curr_id, TAGST, addr, data)
    self.curr_id += 1

  # TAGLA
  def send_tagla(self, way, index):
    addr = self.get_addr(way, index)
    self.tg.send(self.curr_id, TAGLA, addr) 
    self.curr_id += 1

  # TAGLV
  def send_taglv(self, way, index):
    addr = self.get_addr(way, index)
    self.tg.send(self.curr_id, TAGLV, addr) 
    self.curr_id += 1

  # TAGFL
  def send_tagfl(self, way, index):
    addr = self.get_addr(way, index)
    self.tg.send(self.curr_id, TAGFL, addr)
    self.curr_id += 1

  # AINV
  def send_ainv(self, addr):
    self.tg.send(self.curr_id, AINV, addr)
    self.curr_id += 1

  # ALOCK
  def send_alock(self, addr):
    self.tg.send(self.curr_id, ALOCK, addr)
    self.curr_id += 1

  # AFLINV
  def send_aflinv(self, addr):
    self.tg.send(self.curr_id, AFLINV, addr)
    self.curr_id += 1

  # AUNLOCK
  def send_aunlock(self, addr):
    self.tg.send(self.curr_id, AUNLOCK, addr)
    self.curr_id += 1


  # BLOCK_LD
  def send_block_ld(self, addr):
    base_addr = addr - (addr % (self.block_size_in_words_p*4))
    self.tg.send(self.curr_id, BLOCK_LD, base_addr)
    self.curr_id += 1

  # SW
  def send_sw(self, addr):
    self.tg.send(self.curr_id, SW, addr, self.curr_data)
    self.curr_data += 1
    self.curr_id += 1
  
  # LW
  def send_lw(self, addr):
    self.tg.send(self.curr_id, LW, addr)
    self.curr_id += 1
    

  #                         #
  #   COMPOSITE functions   #
  #                         #

  # clear all tags in the cache
  def clear_tag(self):
    for way in range(self.ways_p):
      for index in range(self.sets_p):
        self.send_tagst(way, index)

  def flush_inv(self, way, index):
    addr = self.get_addr(way, index)
    self.send_tagfl(way, index)
    self.send_tagst(way, index)

  def flush_inv_all(self):
    for way in range(self.ways_p):
      for index in range(self.sets_p):
        self.flush_inv(way, index)


  #                         #
  #   HELPER FUNCTIONS      #
  #                         #


  def get_addr(self, tag, index, block_offset=0, byte_offset=0):
    addr = tag << 12
    addr += index << 5
    addr += block_offset << 2
    addr += byte_offset
    return addr 

  def wait(self, n):
    if n == 0:
      pass
    elif n == 1:
      self.tg.nop()
    else:
      self.tg.wait(n-1)

  def done(self):
    self.tg.done()

  # max_delay: max delay in number of cycle
  def delay_random(self, max_delay):
    delay = random.randint(0,max_delay)
    if delay != 0:
      self.wait(delay)
