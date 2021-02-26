import sys
import random
from test_base import *

class TestLock1(TestBase):

  def generate(self):
    self.clear_tag()

    set_index = 0

    way_on_locked = self.ways_on_locked
    #way_on_locked = random.randint(0,7)

    for iteration in range(way_on_locked): 
      tag = iteration
      taddr = self.get_addr(tag, set_index)
      self.send_sw(taddr)
    
    # lock way "way_on_locked" of set 0
    tag_locked = way_on_locked # set a specific tag will not be accessed later
    taddr = self.get_addr(tag_locked, set_index)
    self.send_alock(taddr)

    is_always_miss = 1

    if not is_always_miss:
      # A general case: Randomly Acces unlocked ways in set 0
      for iteration in range(50000): 
        tag = random.randint(0,31)
        taddr = self.get_addr(tag,set_index)
        op = random.randint(0,1)
        if op == 0:
          self.send_sw(taddr)
        elif op == 1:
          self.send_lw(taddr)
    else:
      # An extreme case: always access evicted ways in set 0
      for iteration in range(3000): 
        for tag in range(16):
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
