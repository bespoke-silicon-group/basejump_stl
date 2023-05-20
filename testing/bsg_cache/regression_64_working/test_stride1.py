import sys
import random
from test_base import *

class TestStride1(TestBase):

  def generate(self):
    self.clear_tag()
  
    # stride byte
    for stride in range(1,16):
      for n in range((2**13)-1):
        taddr = stride*n
        self.send_sb(taddr)

    for stride in range(1,16):
      for n in range((2**13)-1):
        taddr = stride*n
        self.send_lb(taddr)

    # stride half
    for stride in range(1,16):
      for n in range((2**12)-1):
        taddr = stride*n*2
        self.send_sh(taddr)

    for stride in range(1,16):
      for n in range((2**12)-1):
        taddr = stride*n*2
        self.send_lh(taddr)

    # stride word
    for stride in range(1,16):
      for n in range((2**11)-1):
        taddr = stride*n*4
        self.send_sw(taddr)

    for stride in range(1,16):
      for n in range((2**11)-1):
        taddr = stride*n*4
        self.send_lw(taddr)

    # stride double
    for stride in range(1,16):
      for n in range((2**10)-1):
        taddr = stride*n*8
        self.send_sd(taddr)

    for stride in range(1,16):
      for n in range((2**10)-1):
        taddr = stride*n*8
        self.send_ld(taddr)

    self.tg.done()





# main()
if __name__ == "__main__":
  t = TestStride1()
  t.generate()
