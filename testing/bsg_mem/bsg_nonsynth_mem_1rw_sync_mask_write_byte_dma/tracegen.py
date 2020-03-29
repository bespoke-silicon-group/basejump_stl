from enum import IntEnum

class TraceGen(object):    
    def __init__(self, data_width_p, addr_width_p):
        self._data_width_p = data_width_p
        self._addr_width_p = addr_width_p
        self._mask_width_p = data_width_p>>3
        
    def send_write(self, addr, data, mask=-1):
        trace = "0001_"
        trace += "1_"
        trace += self.format_addr(addr) + "_"
        trace += self.format_data(data) + "_"
        trace += self.format_mask(mask)
        print(trace)

    def send_read(self, addr):
        trace = "0001_"
        trace += "0_"
        trace += self.format_addr(addr) + "_"
        trace += self.format_data(0)    + "_"
        trace += self.format_mask(0)
        print(trace)
        
    def done(self):
        trace = "0011_"
        trace += "0_"
        trace += self.format_addr(0) + "_"
        trace += self.format_data(0) + "_"
        trace += self.format_mask(0)
        print(trace)

    def max_addr(self):
        return (1<<self._addr_width_p)-1
    def max_data(self):
        return (1<<self._data_width_p)-1
    def max_mask(self):
        return (1<<self._mask_width_p)-1
    
    def format_bin_str(self, value, width):
        return format(value, "0" + str(width) + "b")

    def format_addr(self, addr):
        addr &= self.max_addr()
        return self.format_bin_str(addr, self._addr_width_p)

    def format_data(self, data):
        data &= self.max_data()
        return self.format_bin_str(data, self._data_width_p)

    def format_mask(self, mask):
        mask &= self.max_mask()
        return self.format_bin_str(mask, self._mask_width_p)


def basic(tg, n):
    for addr in range(n):
        tg.send_write(addr, addr)
    for addr in range(n):
        tg.send_read(addr)
    return

def basic_random_data(tg, n):
    from random import randint
    for addr in range(n):
        tg.send_write(addr, randint(0, tg.max_data()), tg.max_mask())
    for addr in range(n):
        tg.send_read(addr)
    return

def random_access(tg, n):
    from random import shuffle, randint
    addrs = []
    for i in range(n):
        addrs.append(randint(0, tg.max_addr()))
    for addr in addrs:
        tg.send_write(addr, randint(0, tg.max_data()), randint(0,tg.max_mask()))
    for addr in addrs:
        tg.send_read(addr)
        
if __name__ == "__main__":

    import sys
    data_width = int(sys.argv[1])
    addr_width = int(sys.argv[2])
    
    tg = TraceGen(data_width, addr_width)
    N = 10000
    random_access(tg, N)    
    tg.done()
