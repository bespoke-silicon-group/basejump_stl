
class TagLine(tuple):
    def __new__(cls, btc, width):
        return super().__new__(cls, (btc.tag_idx, width))

    def __init__(self, btc, width):
        btc.tag_idx += 1

    def __repr__(self):
        return f"TagLine(idx={self[0]}, width={self[1]})"

class TagObject(object):
    def __init__(self, btc):
        pass

    def __repr__(self):
        rstr = ""
        for a, f in self.__dict__.items():
            if '__' in a:
                continue
            rstr += f"{a}={f}\n"

        return rstr

class ClkGenPearl(TagObject):
	async_reset_width = 1
	osc_width = 6
	osc_trigger_width = 1
	ds_width = 7
	sel_width = 2
	monitor_reset_width = 1

	def __init__(self, btc):
		self.async_reset   = TagLine(btc, self.async_reset_width)
		self.osc           = TagLine(btc, self.osc_width)
		self.osc_trigger   = TagLine(btc, self.osc_trigger_width)
		self.ds            = TagLine(btc, self.ds_width)
		self.sel           = TagLine(btc, self.sel_width)
		self.monitor_reset = TagLine(btc, self.monitor_reset_width)

class SdrLinkPearl(TagObject):
    token_reset_width = 1
    downstream_reset_width = 1
    downlink_reset_width = 1
    uplink_reset_width = 1
    link_i_disable_width = 1
    link_o_disable_width = 1

    def __init__(self, btc):
        self.token_reset      = TagLine(btc, self.token_reset_width     )
        self.downstream_reset = TagLine(btc, self.downstream_reset_width)
        self.downlink_reset   = TagLine(btc, self.downlink_reset_width  )
        self.uplink_reset     = TagLine(btc, self.uplink_reset_width    )
        self.link_i_disable   = TagLine(btc, self.link_i_disable_width  )
        self.link_o_disable   = TagLine(btc, self.link_o_disable_width  )

class DdrLinkPearl(TagObject):

    def __init__(self, btc):
        self.io_clk_gen = ClkGenPearl(btc)
        self.

class ManycorePodLink(TagObject):
    core_reset_width = 1
    global_y_width = 7
    global_x_width = 7

    def __init__(self, btc):
        self.clk_gen      = ClkGenPearl(btc)
        self.core_reset   = TagLine(btc, self.core_reset_width)
        self.sdr          = SdrLinkPearl(btc)
        self.global_y     = TagLine(btc, self.global_y_width)
        self.global_x     = TagLine(btc, self.global_x_width)

class ManycoreSubpodLink(object):
    core_reset_width = 1
    global_y_width = 7
    global_x_width = 7

    def __init__(self, btc):
        self.clk_gen      = ClkGenPearl(btc)
        self.core_reset   = TagLine(btc, self.core_reset_width)
        self.sdr          = SdrLinkPearl(btc)
        # TODO: Not needed, but synthesized contain it
        # Move to ManycorePodLink when able
        self.sdr_disable  = TagLine(btc, 1)
        self.global_y     = TagLine(btc, self.global_y_width)
        self.global_x     = TagLine(btc, self.global_x_width)


