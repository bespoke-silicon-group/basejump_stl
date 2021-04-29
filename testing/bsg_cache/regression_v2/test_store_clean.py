
import random
from test_base import *

class TestStoreBlockClean(TestBase):

  def generate(self):
    self.clear_tag()
 
    # k = 0
    # for n in range(10000):
    #   # tag = random.randint(0,16)
    #   for tag in range(2*self.ways_p):
    #     index = 0
    #     block_addr = self.get_addr(tag,index)
    #     # self.send_aalloc(block_addr)
    #     if (k % 2 == 0):
    #       self.send_store_block_clean(block_addr)
    #     else: 
    #       self.send_store_block(block_addr)
    #     k = k + 1


    # write some initial data from index 0 - 64,
    # which might be evicted later
    for index_s in range(64):
      for tag_s in range(8):
          taddr = self.get_addr(tag_s, index_s)
          self.send_store_block(taddr)

    # 0   <= index_a <=  31: cache store_clean hit
    for index_s in range(32):
      for tag_s in range(8):
        taddr = self.get_addr(tag_s, index_s)
        self.send_aalloc(taddr)
        self.send_store_block_clean(taddr)
    # 32  <= index_a <=  63: cache store_clean miss, with dirty data writeback
    # 64  <= index_a <= 127: cache store_clean miss, without dirty data writeback
    for index_s in range(32,128):
      for tag_s in range(8,16):
        taddr = self.get_addr(tag_s, index_s)
        self.send_store_block_clean(taddr)

    # read the data written by store_block_clean
    for index_l in range(32):
      for tag_l in range(8):
          taddr = self.get_addr(tag_l, index_l)
          self.send_load_block(taddr)
    for index_l in range(32,128):
      for tag_l in range(8,16):
        taddr = self.get_addr(tag_l, index_l)
        self.send_load_block(taddr)

    # Read the evicted data, make sure they are written back properly
    for index_l in range(32,64):
      for tag_l in range(8):
          taddr = self.get_addr(tag_l, index_l)
          self.send_load_block(taddr)

    # done
    self.tg.done()


# main()
if __name__ == "__main__":
  t = TestStoreBlockClean()
  t.generate()