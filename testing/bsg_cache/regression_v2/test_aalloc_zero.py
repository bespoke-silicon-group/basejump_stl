import random
from test_base import *

class TestAallocZero(TestBase):
  # This test make sure trash data in the cache line allocated is zeroed out.
  # The test result makes sense only when parameter alloc_zero_p == 1,
  # and this test is not included in general all tests

  def generate(self):
    self.clear_tag()
 
    # write some initial data into all cache line,
    # which will be evicted later
    for index_s in range(128):
      for tag_s in range(8):
          taddr = self.get_addr(tag_s, index_s)
          self.send_store_block(taddr)

    # 0   <= index_a <=  63: cache allocate miss, with dirty data writeback and dirty data zero-out
    for index_a in range(128):
      for tag_a in range(8,16):
        taddr = self.get_addr(tag_a, index_a)
        self.send_aalloc(taddr)

    # Read the cache line where there should only be zeros
    for index_l in range(128):
      for tag_l in range(8,16):
          taddr = self.get_addr(tag_l, index_l)
          self.send_load_block(taddr)

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestAallocZero()
  t.generate()