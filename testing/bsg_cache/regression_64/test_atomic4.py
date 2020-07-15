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
      byte_offset = random.choice([0, 4])
      taddr = self.get_addr(tag, index, block_offset, byte_offset)
      if byte_offset == 0:
        op = random.randint(0, 10)
      else:
        op = random.randint(0,19)
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
      elif op == 11:
        self.send_amoswap_w(taddr)
      elif op == 12:
        self.send_amoadd_w(taddr)
      elif op == 13:
        self.send_amoxor_w(taddr)
      elif op == 14:
        self.send_amoand_w(taddr)
      elif op == 15:
        self.send_amoor_w(taddr)
      elif op == 16:
        self.send_amomin_w(taddr)
      elif op == 17:
        self.send_amomax_w(taddr)
      elif op == 18:
        self.send_amominu_w(taddr)
      elif op == 19:
        self.send_amomaxu_w(taddr)

    self.tg.done()





# main()
if __name__ == "__main__":
  t = TestAtomic4()
  t.generate()
