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
    data_width_p = 64
    self.tg = BsgCacheTraceGen(addr_width_p,data_width_p)
    self.curr_data = 1
    self.sets_p = 64
    self.ways_p = 8
    self.block_size_in_words_p = 8


  # TAGST
  def send_tagst(self, way, index, valid=0, lock=0, tag=0):
    addr = self.get_addr(way, index)
    data = (valid << 63) + (lock << 62) + tag
    self.tg.send(TAGST, addr, data)

  # SD
  def send_sd(self, addr):
    self.tg.send(SD, addr, self.curr_data)
    self.curr_data += 1

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
   
  # LD
  def send_ld(self, addr):
    self.tg.send(LD, addr)

  # LW
  def send_lw(self, addr):
    self.tg.send(LW, addr)

  # LH
  def send_lh(self, addr):
    self.tg.send(LH, addr)
  
  # LB
  def send_lb(self, addr):
    self.tg.send(LB, addr)

  # LWU
  def send_lwu(self, addr):
    self.tg.send(LWU, addr)

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

  # AMOADD_W
  def send_amoadd_w(self, addr):
    self.tg.send(AMOADD_W, addr, self.curr_data)
    self.curr_data += 1

  # AMOXOR_W
  def send_amoxor_w(self, addr):
    self.tg.send(AMOXOR_W, addr, self.curr_data)
    self.curr_data += 1

  # AMOAND_W
  def send_amoand_w(self, addr):
    self.tg.send(AMOAND_W, addr, self.curr_data)
    self.curr_data += 1

  # AMOOR_W
  def send_amoor_w(self, addr):
    self.tg.send(AMOOR_W, addr, self.curr_data)
    self.curr_data += 1

  # AMOMIN_W
  def send_amomin_w(self, addr):
    self.tg.send(AMOMIN_W, addr, self.curr_data)
    self.curr_data += 1

  # AMOMAX_W
  def send_amomax_w(self, addr):
    self.tg.send(AMOMAX_W, addr, self.curr_data)
    self.curr_data += 1

  # AMOMINU_W
  def send_amominu_w(self, addr):
    self.tg.send(AMOMINU_W, addr, self.curr_data)
    self.curr_data += 1

  # AMOMAXU_W
  def send_amomaxu_w(self, addr):
    self.tg.send(AMOMAXU_W, addr, self.curr_data)
    self.curr_data += 1

  # AMOSWAP_D
  def send_amoswap_d(self, addr):
    self.tg.send(AMOSWAP_D, addr, self.curr_data)
    self.curr_data += 1

  # AMOADD_D
  def send_amoadd_d(self, addr):
    self.tg.send(AMOADD_D, addr, self.curr_data)
    self.curr_data += 1

  # AMOXOR_D
  def send_amoxor_d(self, addr):
    self.tg.send(AMOXOR_D, addr, self.curr_data)
    self.curr_data += 1

  # AMOAND_D
  def send_amoand_d(self, addr):
    self.tg.send(AMOAND_D, addr, self.curr_data)
    self.curr_data += 1

  # AMOOR_D
  def send_amoor_d(self, addr):
    self.tg.send(AMOOR_D, addr, self.curr_data)
    self.curr_data += 1

  # AMOMIN_D
  def send_amomin_d(self, addr):
    self.tg.send(AMOMIN_D, addr, self.curr_data)
    self.curr_data += 1

  # AMOMAX_D
  def send_amomax_d(self, addr):
    self.tg.send(AMOMAX_D, addr, self.curr_data)
    self.curr_data += 1

  # AMOMINU_D
  def send_amominu_d(self, addr):
    self.tg.send(AMOMINU_D, addr, self.curr_data)
    self.curr_data += 1

  # AMOMAXU_D
  def send_amomaxu_d(self, addr):
    self.tg.send(AMOMAXU_D, addr, self.curr_data)
    self.curr_data += 1

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
    addr += index << 6
    addr += block_offset << 3
    addr += byte_offset
    return addr
