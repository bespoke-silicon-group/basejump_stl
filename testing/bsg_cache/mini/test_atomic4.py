import sys
import random
from test_base import *

class TestAtomic1(TestBase):

  def generate(self):
    self.clear_tag()
  
    for iteration in range(10):
      for n in range(16000):
        tag0 = random.randint(0,9)
        tag1 = random.randint(10,15)
        index = random.randint(0,1)
        block_offset = random.randint(0,self.block_size_in_words_p-1)
        taddr0 = self.get_addr(tag0,index,block_offset)
        taddr1 = self.get_addr(tag1,index,block_offset)
        op = random.randint(0,12)
        if op == 0:
          self.send_sw(taddr0)
        elif op == 1:
          self.send_lw(taddr0)
        elif op == 2:
          self.send_amoswap_w(taddr0)
        elif op == 3:
          self.send_amoadd_w(taddr0)
        elif op == 4:
          self.send_amoxor_w(taddr0)
        elif op == 5:
          self.send_amoand_w(taddr0)
        elif op == 6:
          self.send_amoor_w(taddr0)
        elif op == 7:
          self.send_amomin_w(taddr0)
        elif op == 8:
          self.send_amomax_w(taddr0)
        elif op == 9:
          self.send_amominu_w(taddr0)
        elif op == 10:
          self.send_amomaxu_w(taddr0)
        elif op == 11:
          self.send_io_sw(taddr1)
        elif op == 12:
          self.send_io_lw(taddr1)

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestAtomic1()
  t.generate()
