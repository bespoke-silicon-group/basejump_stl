import sys
import random
from test_base import *


class TestRandomTAGFL(TestBase):

  def generate(self):
    # scrub tag and data
    self.clear_tag()

    for iteration in range(30):
      # random SW
      for n in range(500):
        tag = random.randint(0,9)
        index = random.randint(0,7)
        block_offset = random.randint(0,7)
        taddr = self.get_addr(tag, index, block_offset)
        self.send_sw(taddr)

      # random TAGFL
      for n in range(10):
        way = random.randint(0,7)
        index = random.randint(0,7)
        self.send_tagfl(way, index)

      # random LW
      for n in range(500):
        tag = random.randint(0,9)
        index = random.randint(0,7)
        block_offset = random.randint(0,7)
        taddr = self.get_addr(tag, index, block_offset)
        self.send_lw(taddr)

    self.tg.done()


          
#   main()
if __name__ == "__main__":
  t = TestRandomTAGFL()
  t.generate()
