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
    if opcode == SW or opcode == SH or opcode == SB:
      self.tg.send(self.curr_id, opcode, addr, self.curr_data)
      self.curr_data += 1 
    elif opcode == LW or opcode == LH or opcode == LB or opcode == LHU or opcode == LBU:
      self.tg.send(self.curr_id, opcode, addr)
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


  # stride: byte size
  # max_addr: exclusive upper bound for addr.
  def test_stride(self, stride, max_addr):
    base = 0
    while base < stride:
      i = base
      while i < max_addr:
        self.delay_random(4)
        self.send(SW, i)
        i += stride
      i = base
      while i < max_addr:
        self.delay_random(4)
        self.send(LW, i)
        i += stride
      base += 4


  # num: number of random accesses
  # max_addr: exclusive upper bound for addr.
  def test_random(self, num, max_addr):
    for i in range(num):
      addr = random.randint(0, (max_addr/4)-1)*4
      store_not_load = random.randint(0,1)
      self.delay_random(16)
      if store_not_load:
        self.send(SW, addr)
      else:
        self.send(LW, addr)


  # block_addr: byte addr (can be any offset)
  def test_block_random(self, block_addr):
    base_addr = block_addr - (block_addr % (self.block_size_in_words_p*4))
    block_offset = list(range(0,4*self.block_size_in_words_p,4))
    random.shuffle(block_offset)

    for i in block_offset:
      self.delay_random(13)
      addr = base_addr + i
      op = random.randint(0,2)
      if op == 0:
        self.send(LW, addr)
      elif op == 1:
        self.send(SW, addr)
    
  #
  def test_linear(self, start_addr, length, max_addr):
    start_word_addr = start_addr - (start_addr%4)
    store_not_load = random.randint(0,1)
    if store_not_load:
      for i in range(length):
        taddr = start_word_addr + (i*4)
        if taddr < max_addr:
          self.send(SW, start_word_addr + (i*4))
    else:
      for i in range(length):
        taddr = start_word_addr + (i*4)
        if taddr < max_addr:
          self.send(LW, start_word_addr + (i*4))
  
  def test_byte_half(self, num, max_addr):
    for i in range(num):
      op = random.randint(0,7)
      addr = random.randint(0,max_addr)
      if op == 0:
        self.send(SB, addr)
      elif op == 1:
        self.send(SH, addr)
      elif op == 2:
        self.send(SW, addr)
      elif op == 3:
        self.send(LB, addr)
      elif op == 4:
        self.send(LH, addr)
      elif op == 5:
        self.send(LW, addr)
      elif op == 6:
        self.send(LBU, addr)
      elif op == 7:
        self.send(LHU, addr)
       
      


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
  strides = list(range(4,128,4))
  random.shuffle(strides)
  for i in strides:
    tg.test_stride(i, MAX_ADDR)

  # test_random
  N = 200000
  tg.test_random(N, MAX_ADDR)

  # test_block_random
  for i in range(10000):
    addr = random.randint(0,MAX_ADDR-1)
    tg.test_block_random(addr)

  # test_linear
  for i in range(2000):
    addr = random.randint(0,(MAX_ADDR/4)-1)
    length = random.randint(1,32)
    tg.test_linear(addr,length,MAX_ADDR)

  # test_byte_half
  tg.test_byte_half(50000, MAX_ADDR-1)
  

  # done
  tg.done()


