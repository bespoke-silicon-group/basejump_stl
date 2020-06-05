import sys
import random
from test_base import *

class TestRandom3(TestBase):

  def rand_op(self, taddr):
    op = random.randint(0,7)
    if op == 0:
      self.send_sd(taddr)
    elif op == 1:
      self.send_sw(taddr)
    elif op == 2:
      self.send_ld(taddr)
    elif op == 3:
      self.send_lw(taddr)
    elif op == 4:
      self.send_amoswap_w(taddr)
    elif op == 5:
      self.send_amoor_w(taddr)
    elif op == 6:
      self.send_amoswap_d(taddr)
    elif op == 7:
      self.send_amoor_d(taddr)

    
  def generate(self):
    self.clear_tag()

    for n in range(10000):
      tag = random.randint(0,11)
      index = random.randint(0,1)
      block_offset = random.randint(0, self.block_size_in_words_p-1)
      byte_offset = random.randint(0,1)*4
      taddr = self.get_addr(tag, index, block_offset, byte_offset)
      self.rand_op(taddr)

    for n in range(500):
      tag = random.randint(0,11)
      index = random.randint(0,1)
      for m in range(20):
        block_offset = random.randint(0, self.block_size_in_words_p-1)
        byte_offset = random.randint(0,1)*4
        taddr = self.get_addr(tag, index, block_offset, byte_offset)
        self.rand_op(taddr)


    self.tg.done()





# main()
if __name__ == "__main__":
  t = TestRandom3()
  t.generate()
