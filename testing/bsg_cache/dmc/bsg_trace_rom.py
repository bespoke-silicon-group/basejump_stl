import sys
import random
import time

class TraceGen:
  def __init__(self, addr_width_p, data_width_p):
    self.addr_width_p = addr_width_p
    self.data_width_p = data_width_p

  def send_tagst(self, addr, data):
    trace = "0001_"
    trace += "10000_"
    trace += format(addr, "0"+str(self.addr_width_p)+"b") + "_"
    trace += format(data, "0"+str(self.data_width_p)+"b")
    print(trace)

  def send_lw(self, addr):
    trace = "0001_"
    trace += "00010_"
    trace += format(addr, "0"+str(self.addr_width_p)+"b") + "_"
    trace += (self.data_width_p)*"0"
    print(trace)
    
  def send_sw(self, addr, data):
    trace = "0001_"
    trace += "01010_"
    trace += format(addr, "0"+str(self.addr_width_p)+"b") + "_"
    trace += format(data, "0"+str(self.data_width_p)+"b")
    print(trace)

  def recv_data(self, data):
    trace = "0010_"
    trace += "00000_"
    trace += (self.addr_width_p)*"0" + "_"
    trace += format(data, "0"+str(self.data_width_p)+"b")
    print(trace)

  def test_done(self):
    print("#### DONE ####")
    trace = "0011_"
    trace += "00000_"
    trace += (self.addr_width_p)*"0" + "_"
    trace += (self.data_width_p)*"0"
    print(trace)


if __name__ == "__main__":
  tg = TraceGen(addr_width_p=28, data_width_p=32)
  sets_p = 512
  ways_p = 2
  id_p = int(sys.argv[1])
  random.seed(time.time())
  
  mem_dict = {}
  store_val = id_p 
 
  # clear tags 
  for i in range(sets_p*ways_p):
    tg.send_tagst(addr=(i<<(3+2)), data=0)
    tg.recv_data(data=0)

  for i in range(5):
    addr = (random.randint(0, 2**14) << 5)
    if addr in mem_dict:
      load_not_store = random.randint(0,1)
      if load_not_store == 1:
        tg.send_lw(addr)
        tg.recv_data(mem_dict[addr])
      else:
        tg.send_sw(addr)
        tg.recv_data(0)
        mem_dict[addr] = store_val
        store_val += 4
    else:
      tg.send_sw(addr, store_val)
      tg.recv_data(0)
      mem_dict[addr] = store_val
      store_val += 4
  
  tg.test_done()
