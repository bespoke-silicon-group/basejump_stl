#
#   test_base.py
#
#   test base class
#
#

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


  # TAGST
  def send_tagst(self, way, index, valid=0, lock=0, tag=0):
    addr = self.get_addr(way, index)
    data = (valid << 31) + (lock <<30) + tag
    self.tg.send(TAGST, addr, data)

  # SW
  def send_sw(self, addr):
    self.tg.send(SW, addr, self.curr_data)
    self.curr_data += 1

  # SH
  def send_sh(self, addr):
    self.tg.send(SH, addr, self.curr_data)
    self.curr_data += 1

  # SB
  def send_sb(self, addr):
    self.tg.send(SB, addr, self.curr_data)
    self.curr_data += 1

  # SM
  def send_sm(self, addr, mask):
    self.tg.send(SM, addr, self.curr_data, mask)
    self.curr_data += 1
   
  # LM 
  def send_lm(self, addr, mask):
    self.tg.send(SM, addr, 0, mask)

  # LW
  def send_lw(self, addr):
    self.tg.send(LW, addr)

  # LH
  def send_lh(self, addr):
    self.tg.send(LH, addr)
  
  # LB
  def send_lb(self, addr):
    self.tg.send(LB, addr)

  # LHU
  def send_lhu(self, addr):
    self.tg.send(LHU, addr)
  
  # LBU
  def send_lbu(self, addr):
    self.tg.send(LBU, addr)

  # AMOSWAP_W
  def send_amoswap_w(self, addr):
    self.tg.send(AMOSWAP_W, addr, self.curr_data)
    self.curr_data += 1
    
  # AMOOR_W
  def send_amoor_w(self, addr):
    self.tg.send(AMOOR_W, addr, self.curr_data)
    self.curr_data += 1

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
