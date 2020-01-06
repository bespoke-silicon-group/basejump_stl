import sys
import random
from test_base import *


class TestCleanRead(TestBase):

  def generate(self):
    # scrub tag and data
    self.clear_tag()
    for i in range(self.MAX_ADDR/4):
      self.send(SW, 4*i)
    self.flush_inv_all()

    # random read for the same set
    for n in range(10000):
      tag = random.randint(0,8)
      index = 0
      for b in range(self.block_size_in_words_p):
        block_offset = b
        addr = self.get_addr(tag, index, block_offset)
        self.send(LW, addr)

    self.tg.done()
          
#   main()
if __name__ == "__main__":
  t = TestCleanRead()
  t.generate()
