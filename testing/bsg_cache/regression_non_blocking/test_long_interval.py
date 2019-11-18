import sys
import random
from test_base import *


class TestLongInterval(TestBase):

  def generate(self):
    # scrub tag and data
    self.clear_tag()

    # random SW/LW
    for n in range(15000):
      delay = random.randint(32,128)
      self.wait(delay)
      
      tag = random.randint(0,8)
      index = 0
      block_offset = random.randint(0,3)
      addr = self.get_addr(tag,index,block_offset) 

      store_not_load = random.randint(0,1)
      if store_not_load:
        self.send(SW, addr)
      else:
        self.send(LW, addr)

    self.tg.done()
          
#   main()
if __name__ == "__main__":
  rd = TestLongInterval()
  rd.generate()
