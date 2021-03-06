import sys
import random
from test_base import *

class TestAtomic1(TestBase):

  def generate(self):
    self.clear_tag()
  
    for iteration in range(10):
      for n in range(10000):
        tag = random.randint(0,9)
        index = random.randint(0,1)
        block_offset = random.randint(0,self.block_size_in_words_p-1)
        taddr = self.get_addr(tag,index,block_offset)
        op = random.randint(0,10)
        if op == 0:
          self.send_sw(taddr)
        elif op == 1:
          self.send_lw(taddr)
        elif op == 2:
          self.send_amoswap_w(taddr)
        elif op == 3:
          self.send_amoadd_w(taddr)
        elif op == 4:
          self.send_amoxor_w(taddr)
        elif op == 5:
          self.send_amoand_w(taddr)
        elif op == 6:
          self.send_amoor_w(taddr)
        elif op == 7:
          self.send_amomin_w(taddr)
        elif op == 8:
          self.send_amomax_w(taddr)
        elif op == 9:
          self.send_amominu_w(taddr)
        elif op == 10:
          self.send_amomaxu_w(taddr)

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestAtomic1()
  t.generate()
