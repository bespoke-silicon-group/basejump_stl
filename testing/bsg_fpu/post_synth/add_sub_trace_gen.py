import math
import struct

class FPUAddSubTraceGen:
  def add(self, a, b):
    trace1 = "0001_0_"
    trace1 += self.convert_float_bin_string(a)
    trace1 += "_"
    trace1 += self.convert_float_bin_string(b)
    print(trace1)
    trace2 = "0010_" + "0" + "_" + 32*"0" + "_"
    trace2 += self.convert_float_bin_string(a+b)
    print(trace2)
    

  def convert_float_bin_string(self, f):
    hx = struct.unpack('<I', struct.pack('<f', f))[0]
    return format(hx, "032b")
  

if __name__ == "__main__":
  tg = FPUAddSubTraceGen()
  tg.add(math.pi, math.e)
