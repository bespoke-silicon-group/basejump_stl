import sys
import random
from test_base import *

class TestStoreLoad(TestBase):
  def get_random_addr(self):
    tag = random.randint(0,9)
    index = random.randint(0,1)
    block_offset = random.randint(0,self.block_size_in_words_p-1)
    taddr = self.get_addr(tag,index,block_offset)
    return taddr

  def generate(self):
    self.clear_tag()
    random.seed(0)

    for n in range(1000):
      taddr1 = self.get_random_addr()
      taddr2 = self.get_random_addr()
      self.send_sw(taddr1)
      self.send_sw(taddr2)
      self.send_lw(taddr1)
    for n in range(1000):
      taddr1 = self.get_random_addr()
      taddr2 = self.get_random_addr()
      self.send_sw(taddr1)
      self.send_sw(taddr2)
      self.send_lw(taddr1)
      self.send_lw(taddr2)
    for n in range(1000):
      taddr1 = self.get_random_addr()
      taddr2 = self.get_random_addr()
      self.send_sw(taddr1)
      self.send_sw(taddr2)
      self.send_lw(taddr2)
      self.send_lw(taddr1)
    for n in range(1000):
      taddr1 = self.get_random_addr()
      taddr2 = self.get_random_addr()
      taddr3 = self.get_random_addr()
      self.send_sw(taddr1)
      self.send_sw(taddr2)
      self.send_sw(taddr3)
      self.send_lw(taddr1)
    for n in range(1000):
      taddr1 = self.get_random_addr()
      taddr2 = self.get_random_addr()
      taddr3 = self.get_random_addr()
      self.send_sw(taddr1)
      self.send_sw(taddr2)
      self.send_sw(taddr3)
      self.send_lw(taddr1)
      self.send_lw(taddr2)
    for n in range(1000):
      taddr1 = self.get_random_addr()
      taddr2 = self.get_random_addr()
      self.send_sw(taddr1)
      self.send_sw(taddr2)
      self.send_sw(taddr2)
      self.send_lw(taddr1)
      self.send_lw(taddr1)

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestStoreLoad()
  t.generate()
