import sys
import random
from test_base import *

class TestStoreLoad(TestBase):

  def generate(self):
    self.clear_tag()
    random.seed(0)
  
    #for n in range(2500):
    #  tag = random.randint(0,9)
    #  index = random.randint(0,1)
    #  block_offset = random.randint(0,self.block_size_in_words_p-1)
    #  taddr = self.get_addr(tag,index,block_offset)
    #  self.send_sw(taddr)
    #  self.send_lw(taddr)

    for n in range(2500):
      tag = random.randint(0,9)
      index = random.randint(0,1)
      block_offset = random.randint(0,self.block_size_in_words_p-1)
      taddr = self.get_addr(tag,index,block_offset)
      tag = random.randint(0,9)
      index = random.randint(0,1)
      block_offset = random.randint(0,self.block_size_in_words_p-1)
      taddr1 = self.get_addr(tag,index,block_offset)
      self.send_sw(taddr)
      self.send_sw(taddr1)
      self.send_lw(taddr)

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestStoreLoad()
  t.generate()
