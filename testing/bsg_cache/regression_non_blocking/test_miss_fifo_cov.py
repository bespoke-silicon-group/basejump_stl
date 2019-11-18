import sys
import random
from test_base import *

class TestMissFIFOCov(TestBase):

  def generate(self):
    # scrub tag and data
    self.clear_tag()

    # random SW/LW
    for iternation in range(1000):
      index = 0
      for tag in range(9):
        addr0 = self.get_addr(tag,index,0)
        addr1 = self.get_addr(tag,index,1)
        self.send_sw(addr0)
        self.send_sw(addr1)
        self.wait(random.randint(64,160)) 
        self.send_lw(addr0)
        self.send_lw(addr1)
        self.wait(random.randint(64,160)) 

    self.tg.done()
          
#   main()
if __name__ == "__main__":
  t = TestMissFIFOCov()
  t.generate()
