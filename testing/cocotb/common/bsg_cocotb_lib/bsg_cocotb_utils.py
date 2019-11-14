import cocotb

from cocotb.drivers import Driver
from cocotb.monitors import Monitor
from cocotb.triggers import NextTimeStep, RisingEdge, ReadOnly, ReadWrite


class ReadyValidBusProducer(Driver):
    def __init__(self, entity, name, clock, data_sig, ready_sig, valid_sig):
        Driver.__init__(self)

        self.entity = entity
        self.name = name
        self.clock = clock

        self.log = self.entity._log

        self.data_sig = data_sig
        self.ready_sig = ready_sig
        self.valid_sig = valid_sig

        # Drive initial values to avoid x asserts
        self.valid_sig.setimmediatevalue(0)
        self.log.info("{} created".format(self.name))

    @cocotb.coroutine
    def start(self, data_gen=None, idle_gen=None, max_txns=None):
        if data_gen is not None:
            for i in range(max_txns):
                if idle_gen is not None:
                    for i in range(next(idle_gen)):
                        yield RisingEdge(self.clock)
                yield self.send(next(data_gen))
        else:
            self.log.error("No data generator specified")

    @cocotb.coroutine
    def _driver_send(self, data, sync=True, **kwargs):
        while True:
            yield ReadOnly()
            if self.ready_sig.value:
                break
            yield RisingEdge(self.clock)
        yield NextTimeStep()
        yield ReadWrite()
        self.valid_sig <= 1
        self.data_sig <= data
        yield RisingEdge(self.clock)
        self.valid_sig <= 0


class ValidYumiBusProducer(Driver):
    def __init__(self, entity, name, clock, data_sig, valid_sig, yumi_sig):
        Driver.__init__(self)

        self.entity = entity
        self.name = name
        self.clock = clock

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
                        yield RisingEdge(self.clock)
                yield self.send(next(data_gen))
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
            yield RisingEdge(self.clock)
        yield RisingEdge(self.clock)
        self.valid_sig <= 0


class ValidYumiBusConsumer(Driver):
    def __init__(self, entity, name, clock, data_sig, valid_sig, yumi_sig):
        Driver.__init__(self)

        self.entity = entity
        self.name = name
        self.clock = clock

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
                    yield RisingEdge(self.clock)
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
            yield RisingEdge(self.clock)
        yield NextTimeStep()
        yield ReadWrite()
        self.yumi_sig <= 1
        yield RisingEdge(self.clock)
        self.yumi_sig <= 0


class ReadyValidBusConsumer(Driver):
    def __init__(self, entity, name, clock, data_sig, ready_sig, valid_sig):
        Driver.__init__(self)

        self.entity = entity
        self.name = name
        self.clock = clock

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
                    yield RisingEdge(self.clock)
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
                yield RisingEdge(self.clock)
            yield RisingEdge(self.clock)
            self.ready_sig <= 0


class ReadyValidBusMonitor(Monitor):
    def __init__(
        self,
        entity,
        name,
        clock,
        data_sig,
        ready_sig,
        valid_sig,
        callback=None,
        event=None,
    ):
        self.entity = entity
        self.name = name
        self.clock = clock

        self.log = self.entity._log

        self.data_sig = data_sig
        self.ready_sig = ready_sig
        self.valid_sig = valid_sig

        self.log.info("{} created".format(self.name))
        Monitor.__init__(self, callback, event)

    @cocotb.coroutine
    def _monitor_recv(self):
        clkedge = RisingEdge(self.clock)
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
        clock,
        data_sig,
        valid_sig,
        yumi_sig,
        callback=None,
        event=None,
    ):
        self.entity = entity
        self.name = name
        self.clock = clock

        self.log = self.entity._log

        self.data_sig = data_sig
        self.valid_sig = valid_sig
        self.yumi_sig = yumi_sig

        self.log.info("{} created".format(self.name))
        super(ValidYumiBusMonitor, self).__init__(callback, event)

    @cocotb.coroutine
    def _monitor_recv(self):
        clkedge = RisingEdge(self.clock)
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
