import sys
import random
from test_base import *

class TestAflinv1(TestBase):

  def generate(self):
    self.clear_tag()

    for iteration in range(1000): 
      for n in range(120):
        tag = random.randint(0,11)
        index = 0
        block_offset = random.randint(0,self.block_size_in_words_p-1)
        taddr = self.get_addr(tag,index,block_offset)
        op = random.randint(0,1)
        if op == 0:
         self.send_sw(taddr)
        elif op == 1:
         self.send_lw(taddr)
      for n in range(4):
        tag = random.randint(0,11)
        index = 0
        block_offset = 0
        taddr = self.get_addr(tag,index,block_offset)
        self.send_aflinv(taddr)

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestAflinv1()
  t.generate()
