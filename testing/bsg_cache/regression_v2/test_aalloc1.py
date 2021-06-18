import random
from test_base import *

class TestAalloc1(TestBase):
  # This test make sure cache_line allocation works with either cache miss or cache hit
  # emphasizes on the correctness

  def generate(self):
    self.clear_tag()
 
    # write some initial data from index 0 - 63,
    # which will be evicted later
    for index_s in range(64):
      for tag_s in range(8):
          taddr = self.get_addr(tag_s, index_s)
          self.send_store_block(taddr)

    # 0   <= index_a <=  63: cache allocate miss, with dirty data writeback
    # 64  <= index_a <= 127: cache allocate miss, without dirty data writeback
    for index_a in range(128):
      for tag_a in range(8,16):
        taddr = self.get_addr(tag_a, index_a)
        self.send_aalloc(taddr)
        self.send_store_block(taddr)

    # a special case, cache line allocate hits and overrides the original data
    for index_a in range(96,128):
      for tag_a in range(8,16):
        taddr = self.get_addr(tag_a, index_a)
        self.send_aalloc(taddr)
        self.send_store_block(taddr)

    # Read the evicted data, make sure they are written back properly
    for index_l in range(64):
      for tag_l in range(8):
          taddr = self.get_addr(tag_l, index_l)
          self.send_load_block(taddr)

    # Read the written data with cache line allocation
    for index_l in range(128):
      for tag_l in range(8,16):
          taddr = self.get_addr(tag_l, index_l)
          self.send_load_block(taddr)

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestAalloc1()
  t.generate()