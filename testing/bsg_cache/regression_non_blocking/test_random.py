import sys
import random
from test_base import *


class TestRandom(TestBase):

  def generate(self):
    # scrub tag and data
    self.clear_tag()

    # random SW/LW
    for n in range(200000):
      addr = random.randint(0, (self.MAX_ADDR/4)-1)*4
      store_not_load = random.randint(0,1)
      if store_not_load:
        self.send(SW, addr)
      else:
        self.send(LW, addr)

    self.tg.done()
          
#   main()
if __name__ == "__main__":
  t = TestRandom()
  t.generate()
