
from bsg_tag_trace_gen import *

class BsgPearlTagTraceGen:
	def __init__(self):
		# Hardcoded
		self.num_masters_p = 2
		self.num_clients_p = 1024
		self.max_payload_width_p = 12

		self.tg = TagTraceGen(self.num_masters_p, self.num_clients_p, self.max_payload_width_p)

	############################
	## Primitives
	###########################
	def init(self):
		self.tg.send(masters=0b11, data_not_reset=0, client_id=0, length=0, data=0b0)

	def wait(self, cycles):
		self.tg.wait(cycles)

	def reset(self, client):
		self.tg.send(masters=0b11, data_not_reset=0, client_id=client[0], length=client[1], data=0b1)

	def send(self, client, data):
		self.tg.send(masters=0b11, data_not_reset=1, client_id=client[0], length=client[1], data=data)

	def done(self):
		self.tg.done()

	############################
	## Subroutines
	###########################
	def reset_recurse(self, client):
		for a, f in client.__dict__.items():
			# Skip builtin
			if '__' in a:
				continue
			# Reset tuple
			if isinstance(f, tuple):
				self.reset(f)
				continue
			self.reset_recurse(f)

	def init_clk_gen_pearl(self, clk):
		# reset monitor
		self.send(clk.monitor_reset, 1)

  		# select zero output clk
		self.send(clk.sel, 3)

  		# init trigger to low, init oscillator to zero
  		# OSC INIT VALUE MUST BE ZERO TO AVOID X IN SIMULATION
		self.send(clk.osc_trigger, 0)
		self.send(clk.osc, 0)

  		# reset oscillator and trigger flops
		self.send(clk.async_reset, 1)
  		# take oscillator and trigger flops out of reset
		self.send(clk.async_reset, 0)

  		# reset oscillator and trigger flops (again, to propagate through sync flops)
		self.send(clk.async_reset, 1)
  		# take oscillator and trigger flops out of reset
		self.send(clk.async_reset, 0)

  		# trigger oscillator value
		self.send(clk.osc_trigger, 1)
		self.send(clk.osc_trigger, 0)

  		# reset ds, then set ds value
		self.send(clk.ds, 1)
		self.send(clk.ds, 0)

  		# select ds output clk
		self.send(clk.sel, 2)

		# bring monitor out of reset
		self.send(clk.monitor_reset, 0)


	def init_sdr(self, sdrs):
		if type(sdrs) != list:
			sdrs = [sdrs]

		for sdr in sdrs:
			# init sdr clients
			self.send(sdr.token_reset, 0)
			self.send(sdr.uplink_reset, 1)
			self.send(sdr.downlink_reset, 1)
			self.send(sdr.downstream_reset, 1)

		for sdr in sdrs:
			# perform async token toggle
			self.send(sdr.token_reset, 1)
			self.send(sdr.token_reset, 0)

		for sdr in sdrs:
			# de-assert uplink reset
			self.send(sdr.uplink_reset, 0)

		for sdr in sdrs:
			# de-assert downlink reset
			self.send(sdr.downlink_reset, 0)

		for sdr in sdrs:
			# de-assert downstream reset
			self.send(sdr.downstream_reset, 0)

	def init_ddr(self, ddrs):
		if type (ddrs) != list:
			ddrs = [ddrs]

		for ddr in ddrs:
			# init ddr clients
			self.send(ddr.core_downlink_reset, 1)
			self.send(ddr.core_uplink_reset, 1)
			self.send(ddr.io_async_token_reset, 0)
			self.send(ddr.io_downlink_reset, 1)
			self.send(ddr.io_uplink_reset, 1)

		for ddr in ddrs:
			# init delays
			self.send(ddr.odelay.data0, 0)
			self.send(ddr.odelay.data1, 0)
			self.send(ddr.odelay.data2, 0)
			self.send(ddr.odelay.clk, 0)
			self.send(ddr.idelay.data0, 0)
			self.send(ddr.idelay.data1, 0)
			self.send(ddr.idelay.data2, 0)
			self.send(ddr.idelay.clk, 0)

		for ddr in ddrs:
			# perform async token reset
			self.send(ddr.io_async_token_reset, 1)
			self.send(ddr.io_async_token_reset, 0)

		for ddr in ddrs:
			# de-assert uplink i/o reset
			self.send(ddr.io_uplink_reset, 0)

		for ddr in ddrs:
			# de-assert downlink i/o reset
			self.send(ddr.io_downlink_reset, 1)
			self.send(ddr.io_downlink_reset, 0)

		for ddr in ddrs:
			# de-assert uplink i/o reset
			self.send(ddr.core_uplink_reset, 0)

		for ddr in ddrs:
			# de-assert downlink i/o reset
			self.send(ddr.core_downlink_reset, 0)

