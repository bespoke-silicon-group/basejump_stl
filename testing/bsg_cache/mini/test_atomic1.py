import sys
import random
from test_base import *

class TestAtomic1(TestBase):

  def generate(self):
    self.clear_tag()
  
    for iteration in range(10):
      for n in range(10000):
        tag = random.randint(0,9)
        index = random.randint(0,1)
        block_offset = random.randint(0,self.block_size_in_words_p-1)
        taddr = self.get_addr(tag,index,block_offset)
        op = random.randint(0,2)
        if op == 0:
          self.send_sw(taddr)
        elif op == 1:
          self.send_lw(taddr)
        elif op == 2:
          self.send_amoswap_w(taddr)

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestAtomic1()
  t.generate()
