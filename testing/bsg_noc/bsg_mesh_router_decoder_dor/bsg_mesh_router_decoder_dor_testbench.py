# Import python libraries
import math
import time
import random

# Import cocotb libraries
import cocotb
from cocotb.clock import Clock, Timer
from cocotb.triggers import RisingEdge, FallingEdge, Timer


# Data width, matching width_p parameter in DUT
X_CORD_WIDTH_P = 4
Y_CORD_WIDTH_P = 4

# Testbench iterations
ITERATION = 5000

# Flow control random seed
# Use different seeds on input and output sides for more randomness
CTRL_INPUT_SEED  = 1
CTRL_OUTPUT_SEED = 2

# Testbench clock period
CLK_PERIOD = 10

@cocotb.test()
async def testbench(dut):

    # clock
    clock = Clock(dut.clk_i, CLK_PERIOD, units="ps")
    cocotb.start_soon(clock.start(start_high=False))

    # reset
    dut.reset_i.value = 1
    await Timer(CLK_PERIOD*5, units="ps")
    dut.reset_i.value = 0

    # random generator
    rand = random.Random()
    rand.seed(time.time())

    for i in range(ITERATION):

        await RisingEdge(dut.clk_i)

        # Randomize inputs
        my_x = rand.randint(0, 2**X_CORD_WIDTH_P - 1)
        my_y = rand.randint(0, 2**Y_CORD_WIDTH_P - 1)
        x_dirs = rand.randint(0, 2**X_CORD_WIDTH_P - 1)
        y_dirs = rand.randint(0, 2**Y_CORD_WIDTH_P - 1)
        mc_x = rand.randint(0, 1)
        mc_y = rand.randint(0, 1)

        dut.my_x_i.value = my_x
        dut.my_y_i.value = my_y
        dut.x_dirs_i.value = x_dirs
        dut.y_dirs_i.value = y_dirs
        dut.mc_x.value = mc_x
        dut.mc_y.value = mc_y


        await Timer(1, units="ps")

        req = dut.req_o.value.integer
        req_p = (req >> 0) & 1  # bit 0
        req_w = (req >> 1) & 1  # bit 1
        req_e = (req >> 2) & 1  # bit 2
        req_n = (req >> 3) & 1  # bit 3
        req_s = (req >> 4) & 1  # bit 4

        x_eq = (x_dirs == my_x)
        y_eq = (y_dirs == my_y)

        # if mc_x=1 and forwarding in X, P must be set
        if mc_x and not x_eq:
            assert req_p == 1, \
                f"[{i}] mc_x=1, x not eq, but P not set! " \
                f"my=({my_x},{my_y}) dst=({x_dirs},{y_dirs}) req={bin(req)}"

        # if mc_y=1 and forwarding in Y, P must be set
        if mc_y and not y_eq and x_eq:
            assert req_p == 1, \
                f"[{i}] mc_y=1, y not eq, but P not set! " \
                f"my=({my_x},{my_y}) dst=({x_dirs},{y_dirs}) req={bin(req)}"
        req_bin = dut.req_o.value.binstr  # [S,N,E,W,P] MSB to LSB

        dut._log.info(
            f"[{i:3d}] "
            f"my=({my_x},{my_y}) dst=({x_dirs},{y_dirs}) "
            f"mc_x={mc_x} mc_y={mc_y} | "
            f"req_o={req_bin} (S={req_bin[0]} N={req_bin[1]} E={req_bin[2]} W={req_bin[3]} P={req_bin[4]})"
        )
        

    dut._log.info("Test finished!")