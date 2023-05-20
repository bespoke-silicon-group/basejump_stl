import sys
import random
from test_base import *


class TestStride2(TestBase):
    def generate(self):
      self.clear_tag()

      for x in range(1,13):
        stride = (2**x)-1

        taddr = 0
        while taddr < self.MAX_ADDR:
          self.send_sb(taddr) 
          taddr += stride

        taddr = 0
        while taddr < self.MAX_ADDR:
          self.send_lb(taddr)
          taddr += stride

      # done
      self.tg.done()


# main()
if __name__ == "__main__":
  t = TestStride2()
  t.generate()