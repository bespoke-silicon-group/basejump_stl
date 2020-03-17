from enum import IntEnum

class TraceGen(object):    
    def __init__(self, data_width_p, addr_width_p):
        self._data_width_p = data_width_p
        self._addr_width_p = addr_width_p
        
    def send_write(self, addr, data):
        trace = "0001_"
        trace += "1_"
        trace += self.format_addr(addr) + "_"
        trace += self.format_data(data)
        print(trace)

    def send_read(self, addr):
        trace = "0001_"
        trace += "0_"
        trace += self.format_addr(addr) + "_"
        trace += self.format_data(0)
        print(trace)
        
    def done(self):
        trace = "0011_"
        trace += "0_"
        trace += self.format_addr(0) + "_"
        trace += self.format_data(0)
        print(trace)

    def format_bin_str(self, value, width):
        return format(value, "0" + str(width) + "b")

    def format_addr(self, addr):
        addr &= (1<<self._addr_width_p)-1
        return self.format_bin_str(addr, self._addr_width_p)

    def format_data(self, data):
        data &= (1<<self._data_width_p)-1
        return self.format_bin_str(data, self._data_width_p)
        
        
if __name__ == "__main__":
    tg = TraceGen(8, 10)
    for addr in range(128):
        tg.send_write(addr, addr)
    for addr in range(128):
        tg.send_read(addr)       
    tg.done()
