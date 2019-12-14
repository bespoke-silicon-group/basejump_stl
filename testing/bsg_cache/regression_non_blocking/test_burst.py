import sys
import random
from test_base import *


class TestBurst(TestBase):

  def generate(self):
    # scrub tag and data
    self.clear_tag()
  
    for iteration in range(5000):
      self.wait(random.randint(100,255))

      for n in range(50):
        tag = random.randint(0,9)
        index = 0
        block_offset = random.randint(0,7)
        taddr = self.get_addr(tag, index, block_offset)
        
        store_not_load = random.randint(0,1)
        if store_not_load:
          self.send_sw(taddr)
        else:
          self.send_lw(taddr)

      
    self.tg.done()
          
#   main()
if __name__ == "__main__":
  t = TestBurst()
  t.generate()
