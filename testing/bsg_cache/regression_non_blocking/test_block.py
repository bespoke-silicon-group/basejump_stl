import sys
import random
from test_base import *


class TestBlock(TestBase):
  def generate(self):
    # scrub tag and data
    self.clear_tag()

    for index in range(self.sets_p):
      for t in range(16):
        for b in range(self.block_size_in_words_p):
          addr = (t<<12) + (index<<5) + (b<<2)
          self.send(SW,addr)
      for t in range(16):
        for b in range(self.block_size_in_words_p):
          addr = (t<<12) + (index<<5) + (b<<2)
          self.send(LW,addr)

    self.tg.done()

#   main()
if __name__ == "__main__":
  bl = TestBlock()
  bl.generate()
