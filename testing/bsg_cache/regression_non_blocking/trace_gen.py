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

  def send(self, opcode, addr, mask=0):
    if opcode == SW or opcode == SH or opcode == SB:
      self.tg.send(self.curr_id, opcode, addr, self.curr_data)
      self.curr_data += 1 
    elif opcode == SM:
      self.tg.send(self.curr_id, opcode, addr, self.curr_data, mask)
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
    
  # going straight up
  def test_linear(self, start_addr, length, max_addr):
    start_word_addr = start_addr - (start_addr%4)
    store_not_load = random.randint(0,1)
    if store_not_load:
      for i in range(length):
        self.delay_random(12) # magic delay
        taddr = start_word_addr + (i*4)
        if taddr < max_addr:
          self.send(SW, taddr)
    else:
      for i in range(length):
        self.delay_random(12) # magic delay
        taddr = start_word_addr + (i*4)
        if taddr < max_addr:
          self.send(LW, taddr)

  # going up and down
  def test_updown(self, start_addr, length, max_addr):
    start_word_addr = start_addr - (start_addr%4)
    for i in range(length):
      self.delay_random(5) # magic delay
      store_not_load = random.randint(0,1)
      taddr = start_word_addr + (i*4)
      if taddr < max_addr:
        if store_not_load:
          self.send(SW, taddr)
        else:
          self.send(LW, taddr)
    for i in range(length):
      self.delay_random(5) # magic delay
      store_not_load = random.randint(0,1)
      taddr = start_word_addr + (4*(length-1)) - (i*4)
      if taddr < max_addr:
        if store_not_load:
          self.send(SW, taddr)
        else:
          self.send(LW, taddr)

  # test square
  def test_square(self, start_addr, row, col, max_addr):
    start_word_addr = start_addr - (start_addr%4)
    for r in range(row):
      for c in range(col):
        center_addr = start_word_addr + (c*4) + (4*col*r)
        taddrs = []
        taddrs.append(center_addr - 4 - (col*4))  # top-left
        taddrs.append(center_addr - (col*4))      # top
        taddrs.append(center_addr + 4 - (col*4))  # top-right
        taddrs.append(center_addr + 4)            # right
        taddrs.append(center_addr + 4 + (col*4))  # bot-right
        taddrs.append(center_addr + (col*4))      # bot
        taddrs.append(center_addr - 4 + (col*4))  # bot-left
        taddrs.append(center_addr + 4)            # left
        store_not_load = random.randint(0,1)
        for taddr in taddrs:
          if taddr >= 0 and taddr < max_addr:
            if store_not_load:
              self.send(SW, taddr)
            else:
              self.send(LW, taddr)

  # test z-order
  def test_zorder(self, start_addr, order, max_addr):
    start_word_addr = start_addr - (start_addr%4)
    i_idx = []
    for y in range(2**order):
      for x in range(2**order):
        # interleave x,y bits
        idx = 0
        temp_x = x
        temp_y = y
        for o in range(order):
          xbit = temp_x & 1
          ybit = temp_y & 1
          idx = idx | (xbit << (2*o))
          idx = idx | (ybit << ((2*o)+1))
          temp_x = temp_x >> 1
          temp_y = temp_y >> 1
        i_idx.append(idx)

    z_idx = [0]*(2**(order*2))
    for i in range(2**(order*2)):
      z_idx[i_idx[i]] = i

    store_not_load = random.randint(0,1)
    for z in z_idx:
      taddr = (z*4) + start_word_addr
      if taddr < max_addr:
        if store_not_load:
          self.send(SW, taddr)
        else:
          self.send(LW, taddr)
        
          
      
    

  # going in loop
  def test_loop(self,start_addr,length,loop,max_addr):
    start_word_addr = start_addr - (start_addr%4)
    for l in range(loop):
      for i in range(length):
        store_not_load = random.randint(0,1)
        taddr = start_word_addr + (i*4)
        if taddr < max_addr:
          if store_not_load:
            self.send(SW, taddr)
          else:
            self.send(LW, taddr)
 
  def test_byte_half(self, num, max_addr):
    for i in range(num):
      op = random.randint(0,8)
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
      elif op == 8:
        mask = random.randint(0,3)
        self.send(SM, addr, mask)
       
      


#   main()
if __name__ == "__main__":
  id_width_p = 30
  data_width_p = 32
  addr_width_p = 32
  tg = BsgCacheNonBlockingRegression(id_width_p, addr_width_p, data_width_p)

  tg.wait(10)
  tg.clear_tag()

  MAX_ADDR = 65536 # byte address

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
  for i in range(1000):
    addr = random.randint(0,MAX_ADDR-1)
    length = random.randint(1,64)
    tg.test_linear(addr,length,MAX_ADDR)

  # test updown
  for i in range(1000):
    addr = random.randint(0,MAX_ADDR-1)
    length = random.randint(1,64)
    tg.test_updown(addr,length,MAX_ADDR)

  # test loop
  for i in range(1000):
    addr = random.randint(0,MAX_ADDR-1)
    length = random.randint(1,64)
    loop = random.randint(2,4)
    tg.test_loop(addr,length,loop,MAX_ADDR)

  # test square
  for i in range(100):
    addr = random.randint(0,MAX_ADDR)
    tg.test_square(addr,4,4,MAX_ADDR)
  for i in range(50):
    addr = random.randint(0,MAX_ADDR)
    tg.test_square(addr,8,8,MAX_ADDR)
  for i in range(25):
    addr = random.randint(0,MAX_ADDR)
    tg.test_square(addr,4,8,MAX_ADDR)
  for i in range(25):
    addr = random.randint(0,MAX_ADDR)
    tg.test_square(addr,8,4,MAX_ADDR)
  for i in range(25):
    addr = random.randint(0,MAX_ADDR)
    tg.test_square(addr,12,12,MAX_ADDR)
  for i in range(25):
    addr = random.randint(0,MAX_ADDR)
    tg.test_square(addr,16,16,MAX_ADDR)


  # test z-order
  for i in range(222):
    addr = random.randint(0,MAX_ADDR-1)
    tg.test_zorder(addr,3,MAX_ADDR)

  # test_byte_half
  tg.test_byte_half(50000, MAX_ADDR-1)
 

  # done
  tg.done()


