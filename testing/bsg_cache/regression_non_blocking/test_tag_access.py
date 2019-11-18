import sys
import random
from test_base import *


class TestTagAccess(TestBase):

  def generate(self):
    # scrub tag and data
    self.clear_tag()

    locked_ways = []
    for i in range(self.sets_p):
      locked_ways.append(set()) 

    # random SW/LW
    for n in range(10000):
      self.wait(random.randint(0,10))
  
      index = random.randint(0,self.sets_p-1)
      way = random.randint(0,self.ways_p-1)
      op = random.randint(0,2)
    
      if op == 0:
        # tagst
        valid = random.randint(0,1)
        tag = way+random.randint(0,self.ways_p-1)*self.ways_p
        lock = random.randint(0,1)

        if lock:
          if len(locked_ways[index]) < 6:
            self.send_tagst(way, index, valid, lock, tag)
            locked_ways[index].add(way)
        else:
          self.send_tagst(way, index, valid, lock, tag)
          if way in locked_ways[index]:
            locked_ways[index].remove(way)
          
      elif op == 1:
        # taglv
        self.send_taglv(way, index)
      elif op == 2:
        # tagla
        self.send_tagla(way, index)

    self.tg.done()
          
#   main()
if __name__ == "__main__":
  t = TestTagAccess()
  t.generate()
