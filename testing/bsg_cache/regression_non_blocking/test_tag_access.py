import sys
import random
from test_base import *


class TestTagAccess(TestBase):

  def generate(self):
    # scrub tag and data
    self.clear_tag()

    # random SW/LW
    for n in range(50000):
      index = random.randint(0,self.sets_p-1)
      way = random.randint(0,self.ways_p-1)
      op = random.randint(0,2)
      
      if op == 0:
        # tagst
        lock = random.randint(0,1)
        valid = random.randint(0,1)
        tag = random.randint(0,31)
        self.send_tagst(way, index, valid, lock, tag)
      elif op == 1:
        # taglv
        self.send_taglv(way, index)
      elif op == 2:
        # tagla
        self.send_tagla(way, index)

    self.tg.done()
          
#   main()
if __name__ == "__main__":
  t = TestTagAccess()
  t.generate()
