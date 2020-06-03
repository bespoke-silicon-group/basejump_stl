import sys
import random
from test_base import *

class TestAtomic4(TestBase):

  def generate(self):
    self.clear_tag()

    for n in range(10000):
      tag = random.randint(0,9)
      index = random.randint(0,1)
      block_offset = random.randint(0, self.block_size_in_words_p-1)
      byte_offset = 0
      taddr = self.get_addr(tag, index, block_offset, byte_offset)
      op = random.randint(0,10)
      if op == 0:
        self.send_sd(taddr)
      elif op == 1:
        self.send_ld(taddr)
      elif op == 2:
        self.send_amoswap_d(taddr)
      elif op == 3:
        self.send_amoadd_d(taddr)
      elif op == 4:
        self.send_amoxor_d(taddr)
      elif op == 5:
        self.send_amoand_d(taddr)
      elif op == 6:
        self.send_amoor_d(taddr)
      elif op == 7:
        self.send_amomin_d(taddr)
      elif op == 8:
        self.send_amomax_d(taddr)
      elif op == 9:
        self.send_amominu_d(taddr)
      elif op == 10:
        self.send_amomaxu_d(taddr)

    self.tg.done()





# main()
if __name__ == "__main__":
  t = TestAtomic4()
  t.generate()
