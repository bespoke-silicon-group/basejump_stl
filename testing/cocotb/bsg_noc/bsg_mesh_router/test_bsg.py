# ===============================================================================
# test_bsg.py
#

import cocotb
import logging
import random

from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.result import TestFailure
from cocotb.scoreboard import Scoreboard
from cocotb.triggers import RisingEdge, Timer

from bsg_cocotb_lib import bsg_assert, bsg_top_params
from bsg_cocotb_utils import (
    BsgBaseTestbench,
    ReadyValidBusMonitor,
    ReadyValidBusProducer,
    ValidYumiBusConsumer,
    ValidYumiBusMonitor,
)


class BsgMeshRouterTB(BsgBaseTestbench):
    def __init__(self, dut, clock_sig, reset_sig, log_level=logging.INFO):
        super(BsgMeshRouterTB, self).__init__(dut, clock_sig, reset_sig, log_level)

        p = bsg_top_params()
        width_p = int(p["width_p"])
        x_cord_width_p = int(p["x_cord_width_p"])
        y_cord_width_p = int(p["y_cord_width_p"])

        cord_width_p = x_cord_width_p + y_cord_width_p

        # bsg_noc has SNEWP
        # Set coordinate to (1, 1)
        S, N, E, W, P = (4, 3, 2, 1, 0)
        dut.my_x_i <= 1
        dut.my_y_i <= 1

        data_i = [0] * 5
        v_i = [0] * 5
        yumi_o = [0] * 5

        data_o = [0] * 5
        v_o = [0] * 5
        ready_i = [0] * 5

        print(dut.__dict__)
        #for att in dir(dut):
        #        print (att, getattr(dut,att))

#        data_i[P] = dut.data_i[(P+1)*width_p-1:(P+0)]
#        data_i[W] = dut.data_i[(W+1)*width_p-1:(W+0)]
#        data_i[E] = dut.data_i[(E+1)*width_p-1:(E+0)]
#        data_i[S] = dut.data_i[(S+1)*width_p-1:(S+0)]
#        data_i[N] = dut.data_i[(N+1)*width_p-1:(N+0)]
#
#        data_o[P] = dut.data_o[(P+1)*width_p-1:(P+0)]
#        data_o[W] = dut.data_o[(W+1)*width_p-1:(W+0)]
#        data_o[E] = dut.data_o[(E+1)*width_p-1:(E+0)]
#        data_o[S] = dut.data_o[(S+1)*width_p-1:(S+0)]
#        data_o[N] = dut.data_o[(N+1)*width_p-1:(N+0)]
#
        #proc_data_i   = dut.data_i[1*width_p-1:0*width_p]
        #proc_v_i      = dut.v_i[0*1]
        #proc_yumi_o   = dut.yumi_o[0*1]
        #west_data_i   = dut.data_i[2*width_p-1:1*width_p]
        #west_v_i      = dut.v_i[1*1]
        #west_yumi_o   = dut.yumi_o[1*1]
        #east_data_i   = dut.data_i[3*width_p-1:2*width_p]
        #east_v_i      = dut.v_i[2*1]
        #east_yumi_o   = dut.yumi_o[2*1]
        #north_data_i  = dut.data_i[4*width_p-1:3*width_p]
        #north_v_i     = dut.v_i[3*1]
        #north_yumi_o  = dut.yumi_o[3*1]
        #south_data_i  = dut.data_i[5*width_p-1:4*width_p]
        #south_v_i     = dut.v_i[4*1]
        #south_yumi_o  = dut.yumi_o[4*1]

        #proc_data_o    = dut.data_o[1*width_p-1:0*width_p]
        #proc_ready_i   = dut.ready_i[0*1]
        #proc_v_o       = dut.v_o[0*1]
        #west_data_o    = dut.data_o[2*width_p-1:1*width_p]
        #west_ready_i   = dut.ready_i[1*1]
        #west_v_o       = dut.v_o[1*1]
        #east_data_o    = dut.data_o[3*width_p-1:2*width_p]
        #east_ready_i   = dut.ready_i[2*1]
        #east_v_o       = dut.v_o[2*1]
        #north_data_o   = dut.data_o[4*width_p-1:3*width_p]
        #north_ready_i  = dut.ready_i[3*1]
        #north_v_o      = dut.v_o[3*1]
        #south_data_o   = dut.data_o[5*width_p-1:4*width_p]
        #south_ready_i  = dut.ready_i[4*1]
        #south_v_o      = dut.v_o[4*1]


        #self.dut_idrive = ReadyValidBusProducer(
        #    dut, "Proc iDriver", dut.clk_i, dut.data_i, dut.ready_o, dut.v_i
        #)
        #self.dut_odrive = ValidYumiBusConsumer(
        #    dut, "Proc oDriver", dut.clk_i, dut.data_o, dut.v_o, dut.yumi_i
        #)
        #self.dut_imon = ReadyValidBusMonitor(
        #    dut, "Proc iMonitor", dut.clk_i, dut.data_i, dut.ready_o, dut.v_i, self.model
        #)
        #self.dut_omon = ValidYumiBusMonitor(
        #    dut, "Proc oMonitor", dut.clk_i, dut.data_o, dut.v_o, dut.yumi_i, self.record
        #)

        self.expected_output = []
        #self.scoreboard.add_interface(self.dut_omon, self.expected_output)

    def model(self, transaction):
        self.expected_output.append(transaction)

    def record(self, transaction):
        self.num_txns += 1


#def random_data(min_val=0, max_val=100):
#    while True:
#        yield random.randint(min_val, max_val)
#
#
#def random_delay(min_delay=0, max_delay=5):
#    while True:
#        yield random.randint(min_delay, max_delay)
#
#
#def increasing_delay(min_delay=0, max_delay=5):
#    while True:
#        for i in range(min_delay, max_delay):
#            yield i
#
#
#def decreasing_delay(min_delay=0, max_delay=5):
#    while True:
#        for i in range(max_delay, min_delay, -1):
#            yield i


@cocotb.test()
def loopback_test(dut, max_txns=None, timeout=None):

    p = bsg_top_params()
    width_p = int(p["width_p"])
    x_cord_width_p = int(p["x_cord_width_p"])
    y_cord_width_p = int(p["y_cord_width_p"])

    tb = BsgMeshRouterTB(dut, dut.clk_i, dut.reset_i, logging.INFO).start()
    yield tb.reset()


