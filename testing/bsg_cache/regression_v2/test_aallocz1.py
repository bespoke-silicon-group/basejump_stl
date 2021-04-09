import random
from test_base import *

class TestAallocz1(TestBase):
  # This test make sure the original data in the allocated cache line is zeroed out.

  def generate(self):
    self.clear_tag()
 
    # write 2 cache page of data
    for index_s in range(self.sets_p*2):
      for tag_s in range(8):
          taddr = self.get_addr(tag_s, index_s)
          self.send_store_block(taddr)

    # Allocate the 1st page, allocate miss, with dirty data writeback and data zero-out
    for index_a in range(self.sets_p):
      for tag_a in range(8):
        taddr = self.get_addr(tag_a, index_a)
        self.send_aallocz(taddr)

    # Read the cache line where there should only be zeros
    for index_l in range(self.sets_p):
      for tag_l in range(8):
          taddr = self.get_addr(tag_l, index_l)
          self.send_load_block(taddr)

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestAallocz1()
  t.generate()