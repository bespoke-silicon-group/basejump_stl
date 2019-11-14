import sys
import random
from test_base import *


class TestBlockLD3(TestBase):

  def generate(self):

    self.clear_tag()

    for n in range(50000):
      op = random.randint(0,3)
      tag = random.randint(0,15)
      index = random.randint(0,3)
      taddr = self.get_addr(tag,index)

      if op == 0:
        self.send_block_st(taddr)
      elif op == 1:
        self.send_block_ld(taddr)
      elif op == 2:
        self.send_sw(taddr)
      else:
        self.send_lw(taddr)

    self.tg.done()


  def send_block_st(self, addr):
    base_addr = addr - (addr % (self.block_size_in_words_p*4))
    for i in range(self.block_size_in_words_p):
      self.send_sw(base_addr+(i*4))
    
          
#   main()
if __name__ == "__main__":
  t = TestBlockLD3()
  t.generate()
