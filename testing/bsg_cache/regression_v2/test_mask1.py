import sys
import random
from test_base import *

class TestMask1(TestBase):
  
  def generate(self):
    self.clear_tag()


    for iteration in range(10):
      for i in range(10000):
        tag = random.randint(0,9)
        index = random.randint(0,2)
        block_offset = random.randint(0,self.block_size_in_words_p-1)
        taddr = self.get_addr(tag, index, block_offset)
        store_not_load = random.randint(0,1)
        mask = random.randint(0, 15)
        if store_not_load:
          self.send_sm(taddr, mask)
        else:
          self.send_lm(taddr, mask)

    self.tg.done()
  
# main()
if __name__ == "__main__":
  t = TestMask1()
  t.generate()
