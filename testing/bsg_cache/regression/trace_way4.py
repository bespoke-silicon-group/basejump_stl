#
#   trace_way4.py
#

import sys
sys.path.append('../common')
from bsg_cache_trace_gen import *


#   main()
if __name__ == "__main__":
  data_width_p = 32
  addr_width_p = 32
  tg = BsgCacheTraceGen(addr_width_p, data_width_p)

  #### TEST BEGIN ####

  # TAGST 00000000 0
  for i in range(4):
    tg.send(TAGST, i<<14, 0)
    tg.recv(0)


  # testing PLRU policy
  
  
  # SW LRU -> 011
  tg.send(SW, 0<<14, 0)
  tg.recv(0)

  # SW LRU -> 001
  tg.send(SW, 1<<14, 0)
  tg.recv(0)

  # SW LRU -> 100
  tg.send(SW, 2<<14, 0)
  tg.recv(0)

  # SW LRU -> 000
  tg.send(SW, 3<<14, 0)
  tg.recv(0)


  # TAGLA
  for i in range(4):
    tg.send(TAGLA, i<<14)
    tg.recv(i<<14)

  # SW LRU -> 010
  tg.send(SW, 0, 0)
  tg.recv(0)

  # SW LRU -> 110
  tg.send(SW, 2<<14, 0)
  tg.recv(0)
  
  # SW EVICT WAY1, LRU -> 101
  tg.send(SW, 4<<14, 0)
  tg.recv(0)


  # TAGLA
  tg.send(TAGLA, 0<<14)
  tg.recv(0<<14)
  tg.send(TAGLA, 1<<14)
  tg.recv(4<<14)
  tg.send(TAGLA, 2<<14)
  tg.recv(2<<14)
  tg.send(TAGLA, 3<<14)
  tg.recv(3<<14)

  # SW EVICT W3, LRU -> 000
  tg.send(SW, 1<<14, 0)
  tg.recv(0)

  # TAGLA
  tg.send(TAGLA, 0<<14)
  tg.recv(0<<14)
  tg.send(TAGLA, 1<<14)
  tg.recv(4<<14)
  tg.send(TAGLA, 2<<14)
  tg.recv(2<<14)
  tg.send(TAGLA, 3<<14)
  tg.recv(1<<14)

  # SW, LRU -> 000
  tg.send(SW, 1<<14, 0)
  tg.recv(0)
  tg.send(SW, 3<<14, 0)
  tg.recv(0)

  # TAGLA
  tg.send(TAGLA, 0<<14)
  tg.recv(3<<14)
  tg.send(TAGLA, 1<<14)
  tg.recv(4<<14)
  tg.send(TAGLA, 2<<14)
  tg.recv(2<<14)
  tg.send(TAGLA, 3<<14)
  tg.recv(1<<14)
  
  # SW, LRU -> 100
  tg.send(SW, 2<<14, 0)
  tg.recv(0)

  # SW, LRU -> 111
  tg.send(SW, 3<<14, 0)
  tg.recv(0)

  # SW, EVICT W3, LRU -> 010
  tg.send(SW, 0<<14, 0)
  tg.recv(0)

  # TAGLA
  tg.send(TAGLA, 0<<14)
  tg.recv(3<<14)
  tg.send(TAGLA, 1<<14)
  tg.recv(4<<14)
  tg.send(TAGLA, 2<<14)
  tg.recv(2<<14)
  tg.send(TAGLA, 3<<14)
  tg.recv(0<<14)



  #### DONE ####
  tg.wait(16)
  tg.done()
