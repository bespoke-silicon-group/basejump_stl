import cocotb

from cocotb.clock import Clock
from cocotb.drivers import Driver
from cocotb.monitors import Monitor
from cocotb.result import TestFailure
from cocotb.scoreboard import Scoreboard
from cocotb.triggers import NextTimeStep, RisingEdge, ReadOnly, ReadWrite, Timer


class ReadyValidBusProducer(Driver):
    def __init__(self, entity, name, clock_sig, data_sig, ready_sig, valid_sig):
        Driver.__init__(self)

        self.entity = entity
        self.name = name
        self.clock_sig = clock_sig

        self.log = self.entity._log

        self.data_sig = data_sig
        self.ready_sig = ready_sig
        self.valid_sig = valid_sig

        # Drive initial values to avoid x asserts
        self.valid_sig.setimmediatevalue(0)
        self.log.info("{} created".format(self.name))

    @cocotb.coroutine
    def start(self, data_gen=None, idle_gen=None):
        if data_gen is not None:
            for data in data_gen:
                if idle_gen is not None:
                    for i in range(next(idle_gen)):
                        yield RisingEdge(self.clock_sig)
                yield self.send(data)
        else:
            self.log.error("No data generator specified")

    @cocotb.coroutine
    def _driver_send(self, data, sync=True, **kwargs):
        while True:
            yield ReadOnly()
            if self.ready_sig.value:
                break
            yield RisingEdge(self.clock_sig)
        yield NextTimeStep()
        yield ReadWrite()
        self.valid_sig <= 1
        self.data_sig <= data
        yield RisingEdge(self.clock_sig)
        self.valid_sig <= 0


class ValidYumiBusProducer(Driver):
    def __init__(self, entity, name, clock_sig, data_sig, valid_sig, yumi_sig):
        Driver.__init__(self)

        self.entity = entity
        self.name = name
        self.clock_sig = clock_sig

        self.log = self.entity._log

        self.data_sig = data_sig
        self.valid_sig = valid_sig
        self.yumi_sig = yumi_sig

        # Drive initial values to avoid x asserts
        self.yumi_sig.setimmediatevalue(0)
        self.log.info("{} created".format(self.name))

    @cocotb.coroutine
    def start(self, data_gen=None, idle_gen=None, max_txns=None):
        if data_gen is not None:
            for i in range(max_txns):
                if idle_gen is not None:
                    for i in range(next(idle_gen)):
                        yield RisingEdge(self.clock_sig)
                yield self.send(data)
        else:
            self.log.error("No data generator specified")

    @cocotb.coroutine
    def _driver_send(self, data, sync=True, **kwargs):
        yield NextTimeStep()
        yield ReadWrite()
        self.valid_sig <= 1
        self.data_sig <= data
        while True:
            yield ReadOnly()
            if self.yumi_sig.value:
                break
            yield RisingEdge(self.clock_sig)
        yield RisingEdge(self.clock_sig)
        self.valid_sig <= 0


class ValidYumiBusConsumer(Driver):
    def __init__(self, entity, name, clock_sig, data_sig, valid_sig, yumi_sig):
        Driver.__init__(self)

        self.entity = entity
        self.name = name
        self.clock_sig = clock_sig

        self.data_sig = data_sig
        self.valid_sig = valid_sig
        self.yumi_sig = yumi_sig

        # Drive initial values to avoid x asserts
        self.yumi_sig.setimmediatevalue(0)
        self.log.info("{} created".format(self.name))

    @cocotb.coroutine
    def start(self, backpressure=None):
        while True:
            if backpressure is not None:
                for i in range(next(backpressure)):
                    yield RisingEdge(self.clock_sig)
            yield self.recv()

    # We alias send to receive in busconsumer
    @cocotb.coroutine
    def recv(self):
        yield self.send(None)

    @cocotb.coroutine
    def _driver_send(self, data, sync=True, **kwargs):
        while True:
            yield ReadOnly()
            if self.valid_sig.value:
                break
            yield RisingEdge(self.clock_sig)
        yield NextTimeStep()
        yield ReadWrite()
        self.yumi_sig <= 1
        yield RisingEdge(self.clock_sig)
        self.yumi_sig <= 0


class ReadyValidBusConsumer(Driver):
    def __init__(self, entity, name, clock_sig, data_sig, ready_sig, valid_sig):
        Driver.__init__(self)

        self.entity = entity
        self.name = name
        self.clock_sig = clock_sig

        self.data_sig = data_sig
        self.ready_sig = ready_sig
        self.valid_sig = valid_sig

        # Drive initial values to avoid x asserts
        self.valid_sig.setimmediatevalue(0)
        self.log.info("{} created".format(self.name))

    @cocotb.coroutine
    def start(self, backpressure=None):
        while True:
            if backpressure is not None:
                for i in range(next(backpressure)):
                    yield RisingEdge(self.clock_sig)
            yield self.recv()

    # We alias send to receive in busconsumer
    @cocotb.coroutine
    def recv(self):
        yield self.send(None)

    @cocotb.coroutine
    def _driver_send(self, data, sync=True, **kwargs):
        while True:
            yield NextTimeStep()
            yield ReadWrite()
            self.ready_sig <= 1
            while True:
                yield ReadOnly()
                if self.yumi_sig.value:
                    break
                yield RisingEdge(self.clock_sig)
            yield RisingEdge(self.clock_sig)
            self.ready_sig <= 0


class ReadyValidBusMonitor(Monitor):
    def __init__(
        self,
        entity,
        name,
        clock_sig,
        data_sig,
        ready_sig,
        valid_sig,
        callback=None,
        event=None,
    ):
        self.entity = entity
        self.name = name
        self.clock_sig = clock_sig

        self.log = self.entity._log

        self.data_sig = data_sig
        self.ready_sig = ready_sig
        self.valid_sig = valid_sig

        self.log.info("{} created".format(self.name))
        Monitor.__init__(self, callback, event)

    @cocotb.coroutine
    def _monitor_recv(self):
        clkedge = RisingEdge(self.clock_sig)
        readonly = ReadOnly()
        nts = NextTimeStep()

        def go():
            if not self.ready_sig.value and self.valid_sig.value:
                self.entity._log.error("valid without ready")
            return self.valid_sig.value

        while True:
            yield clkedge
            yield nts
            yield readonly
            if go():
                data = int(self.data_sig.value)
                self.log.debug("{} observed {}".format(self.name, data))
                self._recv(data)


class ValidYumiBusMonitor(Monitor):
    def __init__(
        self,
        entity,
        name,
        clock_sig,
        data_sig,
        valid_sig,
        yumi_sig,
        callback=None,
        event=None,
    ):
        self.entity = entity
        self.name = name
        self.clock_sig = clock_sig

        self.log = self.entity._log

        self.data_sig = data_sig
        self.valid_sig = valid_sig
        self.yumi_sig = yumi_sig

        self.log.info("{} created".format(self.name))
        super(ValidYumiBusMonitor, self).__init__(callback, event)

    @cocotb.coroutine
    def _monitor_recv(self):
        clkedge = RisingEdge(self.clock_sig)
        nts = NextTimeStep()
        readonly = ReadOnly()

        def go():
            if not self.valid_sig.value and self.yumi_sig.value:
                self.entity._log.error("yumi without valid")
            return self.yumi_sig.value

        while True:
            yield clkedge
            yield nts
            yield readonly
            if go():
                data = int(self.data_sig.value)
                self.log.debug("{} observed {}".format(self.name, data))
                self._recv(data)


class BsgBaseTestbench(object):
    def __init__(self, dut, clock_sig, reset_sig, log_level):
        self.num_cycles = 0
        self.num_txns = 0

        self.dut = dut
        self.clock_sig = clock_sig
        self.reset_sig = reset_sig

        self.log = self.dut._log
        self.log.setLevel(log_level)

        self.scoreboard = Scoreboard(dut)

    def start(self, period=5, units="ns"):
        cocotb.fork(Clock(self.clock_sig, period, units=units).start())
        return self

    @cocotb.coroutine
    def reset(self, duration=10):
        self.log.info("Resetting DUT - START")
        self.reset_sig <= 1
        yield Timer(duration, units="ns")
        yield RisingEdge(self.clock_sig)
        self.log.info("Resetting DUT - FINISH")
        self.reset_sig <= 0

    @cocotb.coroutine
    def run(self, max_txns=None, timeout=None):
        for i in range(timeout):
            yield RisingEdge(self.clock_sig)
            if self.num_txns == max_txns:
                self.log.info("Test finished with {} txns".format(self.num_txns))
                raise self.scoreboard.result
        self.log.error(
            "Test timed out at {} with {} txns".format(timeout, self.num_txns)
        )
        raise TestFailure
