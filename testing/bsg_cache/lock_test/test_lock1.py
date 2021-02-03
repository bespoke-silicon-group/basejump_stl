import sys
import random
from test_base import *

class TestLock1(TestBase):

  def generate(self):
    self.clear_tag()

    set_index = 0

    #way_to_lock = random.randint(0,7)
    way_to_lock = 7

    for iteration in range(way_to_lock): 
      tag = iteration
      taddr = self.get_addr(tag,set_index)
      self.send_sw(taddr)
    
    # lock way "iteration+1" of set 0
    tag = random.randint(0,15) # set a specific tag will not be accessed later
    taddr = self.get_addr(tag,set_index)
    self.send_alock(taddr)

    # Acces other ways in set 0
    for iteration in range(20000): 
      tag = random.randint(0,15)
      taddr = self.get_addr(tag,set_index)
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
