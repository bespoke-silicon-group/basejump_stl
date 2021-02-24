
import sys
sys.path.append("../common")
from bsg_cache_trace_gen import *

class TestBase:

  MAX_ADDR = (2**17)

  # default constructor
  def __init__(self):
    addr_width_p = 30
    data_width_p = 32
    self.tg = BsgCacheTraceGen(addr_width_p,data_width_p)
    self.curr_data = 1
    self.sets_p = 128
    self.ways_p = 8
    self.block_size_in_words_p = 8
    self.ways_on_locked = int(sys.argv[1])


  # TAGST
  def send_tagst(self, way, index, valid=0, lock=0, tag=0):
    addr = self.get_addr(way, index)
    data = (valid << 31) + (lock <<30) + tag
    self.tg.send(TAGST, addr, data)

  # SW
  def send_sw(self, addr):
    self.tg.send(SW, addr, self.curr_data)
    self.curr_data += 1

  # LW
  def send_lw(self, addr):
    self.tg.send(LW, addr)

  # ALOCK
  def send_alock(self, addr):
    self.tg.send(ALOCK, addr)
    
  # AUNLOCK
  def send_aunlock(self, addr):
    self.tg.send(AUNLOCK, addr)

  # TAGFL
  def send_tagfl(self, addr):
    self.tg.send(TAGFL, addr)

  # AFL
  def send_afl(self, addr):
    self.tg.send(AFL, addr)

  # AFLINV
  def send_aflinv(self, addr):
    self.tg.send(AFLINV, addr)

  # nop
  def send_nop(self, n=1):
    for i in range(n):
      self.tg.nop()

  #                         #
  #   COMPOSITE FUNCTIONS   #
  #                         #

  def clear_tag(self):
    for way in range(self.ways_p):
      for index in range(self.sets_p):
        self.send_tagst(way, index)


  #                       #
  #   HELPER FUNCTIONS    #
  #                       #

  def get_addr(self, tag, index, block_offset=0, byte_offset=0):
    addr = tag << 12
    addr += index << 5
    addr += block_offset << 2
    addr += byte_offset
    return addr
