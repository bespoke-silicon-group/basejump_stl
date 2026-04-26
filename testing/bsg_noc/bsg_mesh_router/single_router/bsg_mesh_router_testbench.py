import math
import time
import random

import cocotb
from cocotb.clock import Clock, Timer
from cocotb.triggers import RisingEdge, FallingEdge, Timer


ITERATION = 5000

IN_DIRS = 5
OUT_DIRS = 5

IN_DIRS_MAX_DECIMAL = (1 << IN_DIRS) - 1 # 31
OUT_DIRS_MAX_DECIMAL = (1 << OUT_DIRS) - 1 # 31

X_COORD_WIDTH = 2
Y_COORD_WIDTH = 2

X_COORD_MAX_DECIMAL = (1 << X_COORD_WIDTH) - 1
Y_COORD_MAX_DECIMAL = (1 << Y_COORD_WIDTH) - 1

# keep routers coords fixed, change destination coords per test
MY_X = 1
MY_Y = 1


CLK_PERIOD = 10

# define port mappings
P, W, E, N, S = 0, 1, 2, 3, 4

@cocotb.test()
async def testbench(dut):
    clock = Clock(dut.clk_i, CLK_PERIOD, units="ps")
    cocotb.start_soon(clock.start(start_high=False))

    dut.reset_i.value = 1
    await Timer(CLK_PERIOD*5, units="ps")
    dut.reset_i.value = 0

    rand = random.Random()
    rand.seed = time.time()

    # for i in range (ITERATION):
        # await RisingEdge(dut.clk_i)

        # src_port = random.randint(0, IN_DIRS - 1)

        # dest_x = rand.randint(0, X_COORD_MAX_DECIMAL)
        # dest_y = rand.randint(0, Y_COORD_MAX_DECIMAL)
        # mc_x = rand.randint(0, 1)
        # mc_y = rand.randint(0, 1)
        # packet = (dest_y << (2 + X_COORD_WIDTH)) | (dest_x << 2) | (mc_y << 1) | mc_x

        # v_i = rand.randint(0, IN_DIRS_MAX_DECIMAL)
        # ready_and_i = rand.randint(0, OUT_DIRS_MAX_DECIMAL)
        # my_x_i = MY_X
        # my_y_i = MY_Y

        # dut.data_i[src_port].value = packet
        # dut.v_i[src_port].value = 1
        # dut.ready_and_i.value = ready_and_i
        # dut.my_x_i.value = my_x_i
        # dut.my_y_i.value = my_y_i




    # Test a simple send from West port to East
    await RisingEdge(dut.clk_i)
    await Timer(1, units="ps")

    src_port = W
    dest_port = E

    dest_x = 2
    dest_y = 1
    mc_x = 0
    mc_y = 0
    packet = (dest_y << (2 + X_COORD_WIDTH)) | (dest_x << 2) | (mc_y << 1) | mc_x

    ready_and_i = (1 << dest_port)  # destination port is East
    my_x_i = MY_X  # (1, 1)
    my_y_i = MY_Y

    
    
    dut.data_i[src_port].value = packet
    dut.v_i[src_port].value = 1
    dut.ready_and_i.value = ready_and_i
    dut.my_x_i.value = my_x_i
    dut.my_y_i.value = my_y_i

    # Wait for the handshake
    max_cycles = 10
    v_o = 0
    data_o = 0
    yumi_o = 0
    for _ in range(max_cycles):
        await RisingEdge(dut.clk_i)
        await Timer(1, units="ps") 
        if dut.yumi_o.value[src_port] == 1:
            success = True
            # Capture the data while yumi is high!
            yumi_o = 1
            data_o = dut.data_o[dest_port].value
            v_o = (dut.v_o.value >> dest_port) & 1
            break

    assert v_o == 1, \
        f"v_o at port {dest_port} not set!"
    
    assert data_o == packet, \
        f"output data packet at port {dest_port} modified from original!"

    assert yumi_o == 1, \
        "Router did not accept the input packet (yumi_o low)"

    dut.v_i[src_port].value = 0
    dut.ready_and_i.value = 0

    dut._log.info("Test finished!")