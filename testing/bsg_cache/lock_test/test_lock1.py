import sys
import random
from test_base import *

class TestLock1(TestBase):

  def generate(self):
    self.clear_tag()

    # lock one way x of each set
    for set_inedx in range(0, 127):
        tag = 1 # set a specific tag will not be accessed later
        taddr = self.get_addr(tag,set_inedx)
        self.send_alock(taddr)

    for iteration in range(10000): 
      tag = random.randint(0,7)
      index = 0
      block_offset = 0
      taddr = self.get_addr(tag,index,block_offset)
      op = random.randint(0,1)
      if op == 0:
        self.send_sw(taddr)
      elif op == 1:
        self.send_lw(taddr)
         
    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestLock1()
  t.generate()
