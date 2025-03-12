import sys
import random
from test_base import *

class TestStoreLoad2(TestBase):

  def get_random_addr(self):
    tag = random.randint(0,15)
    index = random.randint(0,1)
    block_offset = random.randint(0,3)
    taddr = self.get_addr(tag,index,block_offset)
    return taddr

  def generate(self):
    self.clear_tag()
    random.seed(0)

    # increasing random delay
    for max_interval in range(100):
      for i in range(1000):
        self.send_nop(random.randint(0,max_interval))

        store_not_load = random.randint(0,1)
        taddr = self.get_random_addr()
        if store_not_load:
          self.send_sw(taddr)
        else:
          self.send_lw(taddr)

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestStoreLoad2()
  t.generate()
