import sys
import random
from test_base import *

class TestRandom2(TestBase):
  
  def generate(self):
    self.clear_tag()
  
    for iteration in range(10):
      for n in range(1000):
        tag = random.randint(0,9)
        index = random.randint(0,2)
        block_offset = random.randint(0,3)
        taddr = self.get_addr(tag,index,block_offset)
        self.send_sw(taddr)
      for n in range(1000):
        tag = random.randint(0,9)
        index = random.randint(0,2)
        block_offset = random.randint(0,3)
        taddr = self.get_addr(tag,index,block_offset)
        self.send_lw(taddr)

    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestRandom2()
  t.generate()
