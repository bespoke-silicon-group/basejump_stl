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
from cocotb.triggers import NextTimeStep, ReadOnly, RisingEdge, Timer

from bsg_cocotb_lib import bsg_assert, bsg_assert_sig, bsg_top_params
from bsg_cocotb_utils import (
    BsgBaseTestbench,
    ReadyValidBusMonitor,
    ReadyValidBusProducer,
    ValidYumiBusConsumer,
    ValidYumiBusMonitor,
)


class BsgTwoFifoTB(BsgBaseTestbench):
    def __init__(self, dut, clock_sig, reset_sig, log_level=logging.INFO):
        super(BsgTwoFifoTB, self).__init__(dut, clock_sig, reset_sig, log_level)

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

        self.expected_output = []
        self.scoreboard.add_interface(self.dut_omon, self.expected_output)

    def model(self, transaction):
        self.expected_output.append(transaction)

    def record(self, transaction):
        self.num_txns += 1


# Streaming generators
def constant_delay(val=0, max_pkts=100):
    for _ in range(max_pkts):
        yield val


def random_data(min_val=0, max_val=100, max_pkts=100):
    for _ in range(max_pkts):
        yield random.randint(min_val, max_val)


def random_delay(min_delay=0, max_delay=5, max_pkts=100):
    for _ in range(max_pkts):
        yield random.randint(min_delay, max_delay)


def increasing_delay(min_delay=0, max_delay=5, max_pkts=100):
    for num_pkts in range(max_pkts):
        yield num_pkts % (max_delay - min_delay)


def decreasing_delay(min_delay=0, max_delay=5, max_pkts=100):
    for num_pkts in range(max_pkts, 0, -1):
        yield num_pkts % (max_delay - min_delay)


@cocotb.test()
def test_single_and_empty(dut, max_txns=None, timeout=None):
    p = bsg_top_params()
    width_p = int(p["width_p"])

    tb = BsgTwoFifoTB(dut, dut.clk_i, dut.reset_i, logging.INFO).start()
    yield tb.reset()

    # Quiescent start
    yield RisingEdge(dut.clk_i)
    yield RisingEdge(dut.clk_i)
    yield RisingEdge(dut.clk_i)
    yield RisingEdge(dut.clk_i)
    yield RisingEdge(dut.clk_i)

    # Should be ready because it's empty
    bsg_assert_sig(dut.ready_o, 1)
    # Should not be valid because we haven't sent in data yet
    bsg_assert_sig(dut.v_o, 0)

    # Send in some data, ensure no bypass through the fifo
    yield RisingEdge(dut.clk_i)
    data = 1
    cocotb.fork(tb.dut_idrive.send(data))
    bsg_assert_sig(int(dut.v_o.value), 0)

    # Wait a cycle, should have data then
    yield RisingEdge(dut.clk_i)
    bsg_assert_sig(dut.v_o, 1)
    bsg_assert_sig(dut.data_o, 1)
    # Check that we can still enqueue
    bsg_assert_sig(dut.ready_o, 1)

    # Check that data is retained in the fifo
    yield RisingEdge(dut.clk_i)
    yield RisingEdge(dut.clk_i)
    yield RisingEdge(dut.clk_i)
    bsg_assert_sig(dut.v_o, 1)
    bsg_assert_sig(dut.data_o, 1)
    # Check that we can still enqueue
    bsg_assert_sig(dut.ready_o, 1)

    # Pop data off the fifo
    yield RisingEdge(dut.clk_i)
    cocotb.fork(tb.dut_odrive.recv())
    yield RisingEdge(dut.clk_i)
    # Ensure fifo is now empty
    bsg_assert_sig(dut.v_o, 0)


@cocotb.test()
def test_double_and_full(dut, max_txns=None, timeout=None):
    p = bsg_top_params()
    width_p = int(p["width_p"])

    tb = BsgTwoFifoTB(dut, dut.clk_i, dut.reset_i, logging.INFO).start()
    yield tb.reset()

    # Quiescent start
    yield RisingEdge(dut.clk_i)
    yield RisingEdge(dut.clk_i)
    yield RisingEdge(dut.clk_i)
    yield RisingEdge(dut.clk_i)
    yield RisingEdge(dut.clk_i)

    # Should be ready because it's empty
    bsg_assert_sig(dut.ready_o, 1)
    # Should not be valid because we haven't sent in data yet
    bsg_assert_sig(dut.v_o, 0)

    # Send in some data, ensure no bypass through the fifo
    yield RisingEdge(dut.clk_i)
    data = 1
    cocotb.fork(tb.dut_idrive.send(data))
    yield RisingEdge(dut.clk_i)
    cocotb.fork(tb.dut_idrive.send(data))

    # Wait a cycle, should have data then
    yield RisingEdge(dut.clk_i)
    bsg_assert_sig(dut.v_o, 1)
    bsg_assert_sig(dut.data_o, 1)
    # Check that fifo is full
    bsg_assert_sig(dut.ready_o, 0)

    # Check that data is retained in the fifo
    yield RisingEdge(dut.clk_i)
    yield RisingEdge(dut.clk_i)
    bsg_assert_sig(dut.v_o, 1)
    bsg_assert_sig(dut.data_o, 1)
    # Check that the fifo is still full
    bsg_assert_sig(dut.ready_o, 0)

    # Pop data off the fifo
    cocotb.fork(tb.dut_odrive.recv())
    yield RisingEdge(dut.clk_i)
    bsg_assert_sig(dut.v_o, 1)
    cocotb.fork(tb.dut_odrive.recv())
    yield RisingEdge(dut.clk_i)
    # Ensure fifo is now empty
    bsg_assert_sig(dut.v_o, 0)


@cocotb.coroutine
def test_crandom(
    dut,
    data_gen=None,
    idle_gen=None,
    backpressure_gen=None,
    max_txns=None,
    timeout=None,
):

    p = bsg_top_params()
    width_p = int(p["width_p"])

    tb = BsgTwoFifoTB(dut, dut.clk_i, dut.reset_i, logging.INFO).start()
    yield tb.reset()

    cocotb.fork(
        tb.dut_idrive.start(data_gen(max_pkts=max_txns), idle_gen(max_pkts=max_txns))
    )
    cocotb.fork(tb.dut_odrive.start(backpressure_gen(max_pkts=max_txns)))

    yield tb.run(max_txns, timeout)


factory = TestFactory(test_crandom)
factory.add_option("data_gen", [random_data])
factory.add_option(
    "idle_gen", [constant_delay, random_delay, increasing_delay, decreasing_delay]
)
factory.add_option(
    "backpressure_gen",
    [constant_delay, random_delay, increasing_delay, decreasing_delay],
)
factory.add_option("max_txns", [10, 100])
factory.add_option("timeout", [1000])
factory.generate_tests()
