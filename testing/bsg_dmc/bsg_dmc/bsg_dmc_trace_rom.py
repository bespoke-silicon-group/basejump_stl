import sys
import random
import time
import re

# Script adapted from testing/bsg_cache/dmc/bsg_trace_rom.py
class TraceGen:
  def __init__(self, addr_width_p, data_width_p, cmd_width_p, burst_length_p):
    self.addr_width_p = addr_width_p
    self.data_width_p = data_width_p
    self.cmd_width_p = cmd_width_p
    self.burst_length_p = burst_length_p
    self.mask_width_lp = data_width_p/8
    self.zero_padding_width_lp = data_width_p + self.mask_width_lp - addr_width_p;

  def send_read(self, addr):
    trace = "0001_"
    precharge = random.randint(0,1)
    trace += "00"  + format(precharge, str(1)+"b") + "1_" + (self.zero_padding_width_lp)*"0" + "_"
    trace += format(addr, "0"+str(self.addr_width_p)+"b") 
    #+ "_"
    self.print_trace(trace)


  def send_write(self, addr, data, mask):
    trace = "0001_"
    precharge = random.randint(0,1)
    #command and address
    trace += "00" + format(precharge, str(1)+"b") + "0_" + (self.zero_padding_width_lp)*"0" + "_"
    trace += format(addr, "0"+str(self.addr_width_p)+"b")
    #+ "_"
    self.print_trace(trace)

    # Burst
    for i in range(self.burst_length_p-1):
        #tag replay: send
        trace_wdata = "0001_"
        trace_wdata += "1001_"
        trace_wdata += format(mask, "0"+str(self.mask_width_lp)+"b") 
        trace_wdata += format(data, "0"+str(self.data_width_p)+"b") + "_"
        self.print_trace(trace_wdata)

    # Burst termination
    trace_wdata = "0001_"
    trace_wdata += "1010_"
    trace_wdata += format(mask, "0"+str(self.mask_width_lp)+"b") 
    trace_wdata += format(data, "0"+str(self.data_width_p)+"b") + "_"
    self.print_trace(trace_wdata)

    #for i in range(self.burst_length_p):
    #    trace += format(mask, "0"+str(self.mask_width_lp)+"b") + "_"        

  def send_nop(self):
    trace = "0001_"
    trace += "1111_"
    trace += (self.mask_width_lp)*"0" + "_"
    trace += format(0, "0"+str(self.data_width_p)+"b")
    self.print_trace(trace)

  def send_exe(self):
    trace = "0001_"
    trace += "1000_"
    trace += (self.mask_width_lp)*"0" + "_"
    trace += format(0, "0"+str(self.data_width_p)+"b")
    self.print_trace(trace)

  def recv_data(self, data):

    for i in range(self.burst_length_p):
        trace = "0010_"
        trace += "0000_"
        trace += (self.mask_width_lp)*"0" + "_"
        trace += format(data, "0"+str(self.data_width_p)+"b")
        self.print_trace(trace)

    #for i in range(self.burst_length_p):
    #    trace += format(data, "0"+str(self.data_width_p)+"b") + "_"

    #for i in range(self.burst_length_p):
    #    trace += (self.mask_width_lp)*"0" + "_"        

  def test_done(self):
    print("#### DONE ####")
    trace = "0011_"
    trace += "1111_"    
    trace += (self.data_width_p + self.mask_width_lp)*"0"
    self.print_trace(trace)

  def nop(self):
    trace = "0000_"
    trace += "1111_"    
    trace += (self.data_width_p + self.mask_width_lp)*"0" 
    self.print_trace(trace)

  def wait(self, num_cycle):
    trace = "0110_"
    trace += "1111_"    
    trace += format(num_cycle, "0"+str(self.data_width_p + self.mask_width_lp)+"b")
    self.print_trace(trace)
    trace = "0101_"
    trace += "1111_"        
    trace += (self.data_width_p + self.mask_width_lp)*"0" 
    self.print_trace(trace)

  def print_trace(self, data):
      new_data = re.sub(r'_$', '', data)
      print(new_data)

if __name__ == "__main__":
  tg = TraceGen(addr_width_p=28, data_width_p=32, cmd_width_p=4, burst_length_p = 8 )
  id_p = int(sys.argv[1])
  random.seed(time.time())

  mem_dict = {}
  write_val = id_p 

  tg.wait(1000)

  for i in range(10):
    addr = (random.randint(0, 2**22) << 6)
    delay = random.randint(0,10)


    mask_val = 0
    #mask_val = random.randint(0, 2^(tg.mask_width_lp))

    if delay == 0:
      pass
    elif delay == 1:
      tg.nop()
    else:
      tg.wait(delay)

    if addr in mem_dict:
      write_not_read = random.randint(0,1)
      if write_not_read == 0:
        tg.send_read(addr)
        tg.send_exe()
        tg.recv_data(mem_dict[addr])
      else:
        tg.send_write(addr, write_val, mask_val)
        tg.send_exe()
        #tg.recv_data(0)
        mem_dict[addr] = write_val
        write_val += 4
    else:
      tg.send_write(addr, write_val, mask_val)
      tg.send_write(addr, write_val, mask_val)
      tg.send_write(addr, write_val, mask_val)
      tg.send_write(addr, write_val, mask_val)
      tg.send_write(addr, write_val, mask_val)
      tg.send_write(addr, write_val, mask_val)
      tg.send_write(addr, write_val, mask_val)
      tg.send_write(addr, write_val, mask_val)
      tg.send_exe()
      #tg.recv_data(0)
      mem_dict[addr] = write_val
      write_val += 4

  #tg.wait(500)

  # read back everything
  for tu in mem_dict.items():
    delay = random.randint(0,32)

    if delay == 0:
      pass
    elif delay == 1:
      tg.nop()
    else:
      tg.wait(delay)

    tg.send_read(tu[0])
    tg.send_exe()
    tg.recv_data(tu[1])

    for j in range(8):
      tg.send_read(tu[0])
    tg.send_exe()
    for j in range(8):
      tg.recv_data(tu[1])
  tg.test_done()
