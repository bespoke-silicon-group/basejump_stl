import sys
import random
from test_base import *

class TestStoreLoad2(TestBase):

  def get_random_addr0(self):
    tag = random.randint(0,15)
    index = random.randint(0,1)
    block_offset = random.randint(0,3)
    taddr = self.get_addr(tag,index,block_offset)
    return taddr

  def get_random_addr1(self):
    tag = random.randint(16,31)
    index = random.randint(0,1)
    block_offset = random.randint(0,3)
    taddr = self.get_addr(tag,index,block_offset)
    return taddr

  def generate(self):
    self.clear_tag()
    random.seed(0)

    # increasing random delay
    for max_interval in range(100):
      for i in range(3000):
        self.send_nop(random.randint(0,max_interval))

        store_not_load = random.randint(0,1)
        io_op = random.randint(0,1)
        taddr0 = self.get_random_addr0()
        taddr1 = self.get_random_addr1()
        if io_op:
          if store_not_load:
            self.send_io_sw(taddr1)
          else:
            self.send_io_lw(taddr1)
        else:
          if store_not_load:
            self.send_sw(taddr0)
          else:
            self.send_lw(taddr0)

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestStoreLoad2()
  t.generate()
