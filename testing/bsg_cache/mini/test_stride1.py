import sys
import random
from test_base import *


class TestStride1(TestBase):

  def generate(self):
    self.clear_tag()

    for stride in range(1,12): 
      for offset in range(0,stride):
        taddr = offset*4
        while taddr < self.MAX_ADDR:
          self.send_sw(taddr)
          taddr += stride*4

        taddr = offset*4
        while taddr < self.MAX_ADDR:
          self.send_lw(taddr)
          taddr += stride*4

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestStride1()
  t.generate()
