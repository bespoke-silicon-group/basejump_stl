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
    ReadyValidBusMonitor,
    ReadyValidBusProducer,
    ValidYumiBusConsumer,
    ValidYumiBusMonitor,
)


class BsgTwoFifoTB(object):
    def __init__(self, dut, log_level=logging.INFO):
        self.num_cycles = 0
        self.num_txns = 0
        self.expected_output = []

        self.dut = dut

        self.log = self.dut._log
        self.log.setLevel(log_level)

        self.dut_idrive = ReadyValidBusProducer(
            dut, "In Driver", dut.clk_i, dut.data_i, dut.ready_o, dut.v_i
        )
        self.dut_odrive = ValidYumiBusConsumer(
            dut, "Out Driver", dut.clk_i, dut.data_o, dut.v_o, dut.yumi_i
        )
        self.dut_imon = ReadyValidBusMonitor(
            dut, "In Monitor", dut.clk_i, dut.data_i, dut.ready_o, dut.v_i, self.model
        )
        self.dut_omon = ValidYumiBusMonitor(
            dut, "Out Monitor", dut.clk_i, dut.data_o, dut.v_o, dut.yumi_i, self.record
        )
        self.scoreboard = Scoreboard(dut)
        self.scoreboard.add_interface(self.dut_omon, self.expected_output)

    def model(self, transaction):
        self.expected_output.append(transaction)

    def record(self, transaction):
        self.num_txns += 1

    @cocotb.coroutine
    def reset(self, duration=10):
        self.dut._log.info("Resetting DUT")
        self.dut.reset_i <= 1
        self.dut.v_i <= 0
        self.dut.yumi_i <= 0
        yield Timer(duration, units="ns")
        yield RisingEdge(self.dut.clk_i)
        self.dut._log.info("DUT out of reset")
        self.dut.reset_i <= 0

    @cocotb.coroutine
    def run(self, max_txns=None, timeout=None):
        for i in range(timeout):
            yield RisingEdge(self.dut.clk_i)
            if self.num_txns == max_txns:
                self.log.info("Test finished with {} txns".format(self.num_txns))
                raise self.scoreboard.result
        self.log.error("Test timed out at {} with {} txns".format(timeout, max_txns))
        raise TestFailure


def random_data(min_val=0, max_val=100):
    while True:
        yield random.randint(min_val, max_val)


def random_delay(min_delay=0, max_delay=5):
    while True:
        yield random.randint(min_delay, max_delay)


def increasing_delay(min_delay=0, max_delay=5):
    while True:
        for i in range(min_delay, max_delay):
            yield i


def decreasing_delay(min_delay=0, max_delay=5):
    while True:
        for i in range(max_delay, min_delay, -1):
            yield i


@cocotb.coroutine
def run_test(
    dut,
    data_gen=None,
    idle_gen=None,
    backpressure_gen=None,
    max_txns=None,
    timeout=None,
):

    p = bsg_top_params()
    width_p = int(p["width_p"])

    cocotb.fork(Clock(dut.clk_i, 5, units="ns").start())
    tb = BsgTwoFifoTB(dut, logging.INFO)
    yield tb.reset()

    cocotb.fork(tb.dut_idrive.start(data_gen, idle_gen, max_txns))
    cocotb.fork(tb.dut_odrive.start(backpressure_gen))

    yield tb.run(max_txns, timeout)


factory = TestFactory(run_test)
factory.add_option("data_gen", [random_data()])
factory.add_option(
    "idle_gen", [None, random_delay(), increasing_delay(), decreasing_delay()]
)
factory.add_option(
    "backpressure_gen", [None, random_delay(), increasing_delay(), decreasing_delay()]
)
factory.add_option("max_txns", [10, 100])
factory.add_option("timeout", [1000])
factory.generate_tests()
