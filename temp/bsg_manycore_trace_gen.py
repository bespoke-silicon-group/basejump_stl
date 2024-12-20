from __future__ import print_function
from bsg_test_trace_gen import *
from bsg_trace_gen import TraceStruct, TraceField
import copy
from random import getrandbits

class ManycorePacketGenerator:
    TEST_OP_LW = 0
    TEST_OP_SW = 2

    TEST_PKT_CREDIT_RETURN = 0
    TEST_PKT_INT_WB = 1

    def __init__(self, src_x=0, src_y=0):
        self.src_x = src_x
        self.src_y = src_y

        self.mcp = TraceStruct("bsg_manycore_pkt_s").add_field("addr", 28).add_field("op_v2", 4).        add_field("reg_id", 5).add_field("payload", 32).add_field("src_y_cord", 7).add_field("src_x_cord", 7).   add_field("y_cord", 7).add_field("x_cord", 7)
        self.mrp = TraceStruct("bsg_manycore_return_pkt_s").add_field("pkt_type", 2).add_field("data",   32).add_field("reg_id", 5).add_field("y_cord", 7).add_field("x_cord", 7)

    def get_fwd_pkt(self, x, y, addr, data, wr_not_rd):
        m1 = copy.deepcopy(self.mcp)

        # FWD packet
        m1.addr = addr
        m1.op_v2 = ManycorePacketGenerator.TEST_OP_SW if wr_not_rd else ManycorePacketGenerator.         TEST_OP_LW
        m1.reg_id = 0
        m1.payload = data
        m1.src_y_cord = self.src_y
        m1.src_x_cord = self.src_x
        m1.y_cord = y
        m1.x_cord = x

        print(f"// INFO: M1: {m1}")
        return m1

    def get_fwd_pkt_store(self, x, y, addr, data):
        return self.get_fwd_pkt(x, y, addr, data, True)

    def get_fwd_pkt_load(self, x, y, addr, data):
        return self.get_fwd_pkt(x, y, addr, data, False)
    def get_rev_pkt(self, x, y, data, wr_not_rd):
        m2 = copy.deepcopy(self.mrp)

        # REV packet
        m2.pkt_type = ManycorePacketGenerator.TEST_PKT_CREDIT_RETURN if wr_not_rd else                   ManycorePacketGenerator.TEST_PKT_INT_WB
        m2.data = data
        m2.reg_id = 0
        m2.y_cord = y
        m2.x_cord = x
        print(f"// INFO: M2: {m2}")
        return m2

    def get_rev_pkt_store(self, x, y, data):
        return self.get_rev_pkt(x, y, data, True)

    def get_rev_pkt_load(self, x, y, data):
        return self.get_rev_pkt(x, y, data, False)

class ManycoreChipTraceGen(TestTraceGen):
    TEST_LINK_TYPE_FWD = 0
    TEST_LINK_TYPE_REV = 1
    TEST_LINK_TYPE_NOC = 2

    def __init__(self):
        super().__init__()
        self.ts = TraceStruct("bsg_test_rom_manycore_s").add_field("pkt", 100).add_field("typ", 2).      add_field("idx", 5)

    def execute_pkt(self, link, idx, pkt, recv_not_send):
        t1 = copy.deepcopy(self.ts)

        if link == ManycoreChipTraceGen.TEST_LINK_TYPE_FWD:
            link_width = 97
        elif link == ManycoreChipTraceGen.TEST_LINK_TYPE_REV:
            link_width = 53
        else:
            link_width = 64

        if pkt.name == "bsg_manycore_pkt_s":
            pkt_width = 97
        elif pkt.name == "bsg_manycore_return_pkt_s":
            pkt_width = 53
        else:
            pkt_width = 64

        raw = pkt.get_int()
        done = 0
        remaining = pkt_width
        mask = (2**link_width-1)
        while remaining > 0:
            t1.typ = link
            t1.idx = idx
            t1.pkt = raw & mask

            remaining -= link_width
            done += link_width
            raw >>= link_width


            if recv_not_send:
                print(f"// RECV ({done}/{pkt_width}): {t1}")
                self.recv(t1.get_int())
            else:
                print(f"// SEND ({done}/{pkt_width}): {t1}")
                self.send(t1.get_int())

    def send_pkt(self, link, idx, pkt):
        self.execute_pkt(link, idx, pkt, False)

    def recv_pkt(self, link, idx, pkt):
        self.execute_pkt(link, idx, pkt, True)

    def send_fwd_pkt(self, idx, pkt):
        self.send_pkt(ManycoreChipTraceGen.TEST_LINK_TYPE_FWD, idx, pkt)

    def send_rev_pkt(self, idx, pkt):
        self.send_pkt(ManycoreChipTraceGen.TEST_LINK_TYPE_REV, idx, pkt)

    def send_noc_pkt(self, idx, pkt):
        self.send_pkt(ManycoreChipTraceGen.TEST_LINK_TYPE_NOC, idx, pkt)

    def recv_fwd_pkt(self, idx, pkt):
        self.recv_pkt(ManycoreChipTraceGen.TEST_LINK_TYPE_FWD, idx, pkt)

    def recv_rev_pkt(self, idx, pkt):
        self.recv_pkt(ManycoreChipTraceGen.TEST_LINK_TYPE_REV, idx, pkt)

    def recv_noc_pkt(self, idx, pkt):
        self.recv_pkt(ManycoreChipTraceGen.TEST_LINK_TYPE_NOC, idx, pkt)

