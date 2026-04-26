import math
import time
import random

import cocotb
from cocotb.clock import Clock, Timer
from cocotb.triggers import RisingEdge, FallingEdge, Timer

ITERATION = 5000

IN_DIRS = 5
OUT_DIRS = 5

IN_DIRS_MAX_DECIMAL = math.pow(IN_DIRS, 2) - 1
OUT_DIRS_MAX_DECIMAL = math.pow(OUT_DIRS, 2) - 1

X_COORD_WIDTH = 4
Y_COORD_WIDTH = 4

X_COORD_MAX_DECIMAL = math.pow(X_COORD_WIDTH, 2) - 1
Y_COORD_MAX_DECIMAL = math.pow(Y_COORD_WIDTH, 2) - 1

# keep routers coords fixed, change destination coords per test
MY_X = 3
MY_Y = 3


CLK_PERIOD = 10

@cocotb.test()
async def testbench(dut):
    clock = Clock(dut.clk_i, CLK_PERIOD, units="ps")
    cocotb.start_soon(clock.start(start_high=False))

    dut.reset_i.value = 1
    await Timer(CLK_PERIOD*5, units="ps")
    dut.reset_i_value = 0

    rand = random.Random()
    rand.seed = time.time()

    for i in range (ITERATION):
        await RisingEdge(dut.clk_i)

        dest_x = rand.randint(0, X_COORD_MAX_DECIMAL)
        dest_y = rand.randint(0, Y_COORD_MAX_DECIMAL)
        mc_x = rand.randint(0, 1)
        mc_y = rand.randint(0, 1)

        
        # data_i = ...
        v_i = rand.randint(0, IN_DIRS_MAX_DECIMAL)
        ready_and_i = rand.randint(0, OUT_DIRS_MAX_DECIMAL)
        my_x_i = MY_X
        my_y_i = MY_Y
