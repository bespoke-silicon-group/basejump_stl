# Davis Sauer
# 05/2024

# Import python libraries
import math
import time
import random

# Import cocotb libraries
import cocotb
from cocotb.clock import Clock, Timer
from cocotb.triggers import RisingEdge, FallingEdge, Timer


# Data width, matching width_p parameter in DUT
WIDTH_P = 16

# Testbench iterations
ITERATION = 1000

# Flow control random seed
# Use different seeds on input and output sides for more randomness
CTRL_INPUT_SEED  = 1
CTRL_OUTPUT_SEED = 2

# Testbench clock period
CLK_PERIOD = 10


async def input_side_testbench(dut, seed):
    """Handle input traffic"""

    # Create local random generator for data generation
    data_random = random.Random()
    data_random.seed(seed)

    # Create control random generator for flow control
    control_random = random.Random()
    control_random.seed(CTRL_INPUT_SEED)

    # Initialize DUT interface values
    dut.v_i.value = 0
    dut.data_i.value = 0
    dut.enq_not_deq_i.value = 1

    # Wait for reset deassertion
    while 1:
        await RisingEdge(dut.clk_i); await Timer(1, units="ps")
        if dut.reset_i == 0: break

    # Main iterations
    i = 0
    data = []
    data_idx = 0
    while 1:
        await RisingEdge(dut.clk_i); await Timer(1, units="ps")
        rng = control_random.random()
        if dut.full_o.value == 0 and rng >= 0.5:  # write
            # Assert DUT valid signal
            dut.v_i.setimmediatevalue(1)
            dut.enq_not_deq_i.setimmediatevalue(1)
            # Generate send data
            value = math.floor(data_random.random()*pow(2, WIDTH_P))
            data.append(value)
            dut.data_i.setimmediatevalue(value)
            await RisingEdge(dut.clk_i); await Timer(1, units="ps")
            # Deassert DUT signals
            dut.v_i.setimmediatevalue(0)
            dut.enq_not_deq_i.setimmediatevalue(value > pow(2, WIDTH_P)/2)
            # iteration increment
            i += 1
            # Check iteration
            if i == ITERATION:
                # Test finished
                break
        elif dut.empty_o.value == 0:  # read
            # Assert DUT signals
            dut.v_i.setimmediatevalue(1)
            dut.enq_not_deq_i.setimmediatevalue(0)
            await RisingEdge(dut.clk_i); await Timer(1, units="ps")
            assert dut.data_o.value == data[data_idx], "data mismatch!"
            # Deassert DUT signals
            dut.v_i.setimmediatevalue(0)
            dut.enq_not_deq_i.setimmediatevalue(data[data_idx] > pow(2, WIDTH_P)/2)
            data_idx += 1
        else: # do nothing
            await RisingEdge(dut.clk_i); await Timer(1, units="ps")

    await RisingEdge(dut.clk_i); await Timer(1, units="ps")
    
    # Deassert DUT valid signal
    dut.v_i.value = 0

@cocotb.test()
async def testbench(dut):
    """Try accessing the design."""

    # Random seed assignment
    seed = "fifo"

    # Create a 10ps period clock on DUT port clk_i
    clock = Clock(dut.clk_i, CLK_PERIOD, units="ps")

    # Start the clock. Start it low to avoid issues on the first RisingEdge
    clock_thread = cocotb.start_soon(clock.start(start_high=False))

    # Launch input and output testbench threads
    input_thread = cocotb.start_soon(input_side_testbench(dut, seed))

    # Reset initialization
    dut.reset_i.value = 1

    # Wait for 5 clock cycles
    await Timer(CLK_PERIOD*5, units="ps")
    await RisingEdge(dut.clk_i); await Timer(1, units="ps")

    # Deassert reset
    dut.reset_i.value = 0

    # Wait for threads to finish
    await input_thread

    # Wait for 5 clock cycles
    await Timer(CLK_PERIOD*5, units="ps")
    await RisingEdge(dut.clk_i); await Timer(1, units="ps")

    # Assert reset
    dut.reset_i.value = 1

    # Wait for 5 clock cycles
    await Timer(CLK_PERIOD*5, units="ps")

    # Test finished!
    dut._log.info("Test finished! Current reset_i value = %s", dut.reset_i.value)
