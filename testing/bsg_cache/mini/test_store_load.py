import sys
import random
from test_base import *

class TestStoreLoad(TestBase):
  def get_random_addr0(self):
    tag = random.randint(0,9)
    index = random.randint(0,1)
    block_offset = random.randint(0,self.block_size_in_words_p-1)
    taddr = self.get_addr(tag,index,block_offset)
    return taddr

  def get_random_addr1(self):
    tag = random.randint(10,15)
    index = random.randint(0,1)
    block_offset = random.randint(0,self.block_size_in_words_p-1)
    taddr = self.get_addr(tag,index,block_offset)
    return taddr

  def generate(self):
    self.clear_tag()
    random.seed(0)

    for n in range(3000):
      taddr1 = self.get_random_addr0()
      taddr2 = self.get_random_addr0()
      taddr3 = self.get_random_addr1()
      taddr4 = self.get_random_addr1()
      self.send_sw(taddr1)
      self.send_io_sw(taddr3)
      self.send_sw(taddr2)
      self.send_io_sw(taddr4)
      self.send_lw(taddr1)
      self.send_io_lw(taddr3)
    for n in range(3000):
      taddr1 = self.get_random_addr0()
      taddr2 = self.get_random_addr0()
      taddr3 = self.get_random_addr1()
      taddr4 = self.get_random_addr1()
      self.send_sw(taddr1)
      self.send_io_sw(taddr3)
      self.send_sw(taddr2)
      self.send_io_sw(taddr4)
      self.send_lw(taddr1)
      self.send_io_lw(taddr3)
      self.send_lw(taddr2)
      self.send_io_lw(taddr4)
    for n in range(3000):
      taddr1 = self.get_random_addr0()
      taddr2 = self.get_random_addr0()
      taddr3 = self.get_random_addr1()
      taddr4 = self.get_random_addr1()
      self.send_sw(taddr1)
      self.send_io_sw(taddr3)
      self.send_io_sw(taddr4)
      self.send_sw(taddr2)
      self.send_lw(taddr2)
      self.send_io_lw(taddr4)
      self.send_io_lw(taddr3)
      self.send_lw(taddr1)
    for n in range(3000):
      taddr1 = self.get_random_addr0()
      taddr2 = self.get_random_addr0()
      taddr3 = self.get_random_addr0()
      taddr4 = self.get_random_addr1()
      taddr5 = self.get_random_addr1()
      taddr6 = self.get_random_addr1()
      self.send_sw(taddr1)
      self.send_sw(taddr2)
      self.send_sw(taddr3)
      self.send_io_sw(taddr4)
      self.send_io_sw(taddr5)
      self.send_io_sw(taddr6)
      self.send_lw(taddr1)
      self.send_io_lw(taddr4)
    for n in range(3000):
      taddr1 = self.get_random_addr0()
      taddr2 = self.get_random_addr0()
      taddr3 = self.get_random_addr0()
      taddr4 = self.get_random_addr1()
      taddr5 = self.get_random_addr1()
      taddr6 = self.get_random_addr1()
      self.send_io_sw(taddr4)
      self.send_io_sw(taddr5)
      self.send_io_sw(taddr6)
      self.send_sw(taddr1)
      self.send_sw(taddr2)
      self.send_sw(taddr3)
      self.send_io_lw(taddr4)
      self.send_io_lw(taddr5)
      self.send_lw(taddr1)
      self.send_lw(taddr2)
    for n in range(3000):
      taddr1 = self.get_random_addr0()
      taddr2 = self.get_random_addr0()
      taddr3 = self.get_random_addr1()
      taddr4 = self.get_random_addr1()
      self.send_sw(taddr1)
      self.send_io_sw(taddr3)
      self.send_sw(taddr2)
      self.send_io_sw(taddr4)
      self.send_sw(taddr2)
      self.send_lw(taddr1)
      self.send_io_lw(taddr3)
      self.send_lw(taddr1)
      self.send_io_lw(taddr3)
    for n in range(3000):
      taddr1 = self.get_random_addr0()
      taddr2 = self.get_random_addr0()
      taddr3 = self.get_random_addr1()
      taddr4 = self.get_random_addr1()
      self.send_sw(taddr1)
      self.send_io_sw(taddr3)
      self.send_sw(taddr2)
      self.send_sw(taddr2)
      self.send_io_lw(taddr3)
      self.send_io_sw(taddr4)
      self.send_lw(taddr1)
      self.send_lw(taddr1)
      self.send_io_lw(taddr4)

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestStoreLoad()
  t.generate()
