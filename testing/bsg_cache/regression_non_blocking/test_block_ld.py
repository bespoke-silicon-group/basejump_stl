import sys
import random
from test_base import *


class TestBlockLD(TestBase):

  def generate(self):

    self.clear_tag()

    for n in range(50000):
      store_not_load = random.randint(0,1)
      tag = random.randint(0, 15)
      index = random.randint(0,self.sets_p-1)
      taddr = self.get_addr(tag,index)

      if store_not_load:
        self.send_block_st(taddr)
      else:
        self.send_block_ld(taddr)

    self.tg.done()


  def send_block_st(self, addr):
    base_addr = addr - (addr % (self.block_size_in_words_p*4))
    for i in range(self.block_size_in_words_p):
      self.send_sw(base_addr+(i*4))
    
          
#   main()
if __name__ == "__main__":
  t = TestBlockLD()
  t.generate()
