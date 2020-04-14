import sys
import random
from test_base import *


class TestStride(TestBase):
  
  def generate(self):
    for stride in range(4, 64, 4):
      self.clear_tag()
      base = 0
      while base < stride:
        # store
        i = base
        while i < self.MAX_ADDR:
          self.send(SW, i)
          i += stride
        # load
        i = base
        while i < self.MAX_ADDR:
          self.send(LW, i)
          i += stride
          base += 4

    self.tg.done()
      
      

#   main()
if __name__ == "__main__":
  st = TestStride()
  st.generate()
