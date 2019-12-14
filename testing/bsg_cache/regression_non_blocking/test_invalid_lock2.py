
import sys
import random
from test_base import *


class TestInvalidLock2(TestBase):

  def generate(self):
    # scrub tag and data
    self.clear_tag()

    for iteration in range(100):
      lock_count = 0
      for w in range(self.ways_p):
        if lock_count < 6:
          lock_this = random.randint(0,1)
          if lock_this:
            self.send_tagst(w, 0, valid=0, lock=1)
            lock_count += 1
    
      for n in range(1000):
        block_offset = random.randint(0,7)
        index = 0
        tag = random.randint(0,15)
        taddr = self.get_addr(tag,index,block_offset)

        store_not_load = random.randint(0,1)
        if store_not_load:
          self.send_sw(taddr)
        else:
          self.send_lw(taddr)

      for w in range(self.ways_p):
        self.flush_inv(w,0)

    self.tg.done()
         


 
#   main()
if __name__ == "__main__":
  t = TestInvalidLock2()
  t.generate()
