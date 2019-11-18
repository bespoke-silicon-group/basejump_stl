import sys
import random
from test_base import *


class TestBlockLD2(TestBase):

  def generate(self):

    self.clear_tag()

    for n in range(50000):
      tag = random.randint(0, 15)
      index = random.randint(0,self.sets_p-1)
      taddr = self.get_addr(tag,index)

      op = random.randint(0,2)
      if op == 0:
        self.send_block_st(taddr)
      elif op == 1:
        self.send_block_ld(taddr)
      else:
        self.send_aflinv(taddr)

    self.tg.done()


  def send_block_st(self, addr):
    base_addr = addr - (addr % (self.block_size_in_words_p*4))
    for i in range(self.block_size_in_words_p):
      self.send_sw(base_addr+(i*4))
    
          
#   main()
if __name__ == "__main__":
  t = TestBlockLD2()
  t.generate()
