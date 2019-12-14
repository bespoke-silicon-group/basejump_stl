import sys
import random
from test_base import *

class TestLdSt(TestBase):

  def generate(self):
    # scrub tag and data
    self.clear_tag()

    # random SW/LW
    for iteration in range(1000):
      for w in range(self.ways_p):
        self.flush_inv(w,0)
      
      for n in range(12*self.block_size_in_words_p):
        tag = random.randint(0,11)
        block_offset = random.randint(0,7)
        taddr = self.get_addr(tag,0,block_offset)
        store_not_load = random.randint(0,1)
        if store_not_load:
          self.send_sw(taddr)
        else:
          self.send_lw(taddr)

    self.tg.done()
          
#   main()
if __name__ == "__main__":
  t = TestLdSt()
  t.generate()
