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
ITERATION = 3500

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
    dut.valid_i.value = 0
    dut.data_i.value = 0

    # Wait for reset deassertion
    while 1:
        await RisingEdge(dut.clk_i); await Timer(1, units="ps")
        if dut.reset_i == 0: break

    # Main iterations
    i = 0
    while 1:
        await RisingEdge(dut.clk_i); await Timer(1, units="ps")
        # Half chance to send data flit
        if control_random.random() >= 0.5:
            # Assert DUT valid signal
            dut.valid_i.setimmediatevalue(1)
            # Check DUT ready signal
            if dut.ready_and_o == 1:
                # Generate send data
                dut.data_i.setimmediatevalue(math.floor(data_random.random()*pow(2, WIDTH_P)))
                # iteration increment
                i += 1
                # Check iteration
                if i == ITERATION:
                    # Test finished
                    break
        else:
            # Deassert DUT valid signal
            dut.valid_i.setimmediatevalue(0)

    await RisingEdge(dut.clk_i); await Timer(1, units="ps")
    # Deassert DUT valid signal
    dut.valid_i.value = 0


async def output_side_testbench(dut, seed):
    """Handle input traffic"""

    # Create local random generator for data generation
    data_random = random.Random()
    data_random.seed(seed)

    # Create control random generator for flow control
    control_random = random.Random()
    control_random.seed(CTRL_OUTPUT_SEED)

    # Initialize DUT interface values
    dut.yumi_cnt_i.value = 0

    # Wait for reset deassertion
    while 1:
        await RisingEdge(dut.clk_i); await Timer(1, units="ps")
        if dut.reset_i == 0: break

    # Main iterations
    i = 0
    while 1:
        await RisingEdge(dut.clk_i); await Timer(2, units="ps") # MUST RUN AFTER INPUT
        if dut.valid_o.value != 0 and control_random.random() >= 0.2:
            available = int(math.log2(dut.valid_o.value + 1))
            to_take = control_random.choice(range(available + 1))
            # print(f"Available: {available}, taking: {to_take}")

            # Assert DUT yumi signal
            dut.yumi_cnt_i.setimmediatevalue(to_take)

            # Generate check data and compare with receive data
            for j in range(to_take):
                value = math.floor(data_random.random()*pow(2, WIDTH_P))
                # print(f"{dut.data_o[j].value} == {value}")
                assert dut.data_o[j].value == value, "data mismatch!"
            # print()

            # iteration increment
            i += to_take
            # Check iteration
            if i == ITERATION:
                # Test finished
                break
        else:
            # Deassert DUT yumi signal
            dut.yumi_cnt_i.setimmediatevalue(0)

    await RisingEdge(dut.clk_i); await Timer(1, units="ps")
    # Deassert DUT yumi signal
    dut.yumi_cnt_i.value = 0


@cocotb.test()
async def testbench(dut):
    """Try accessing the design."""

    # Random seed assignment
    seed = time.time()

    # Create a 10ps period clock on DUT port clk_i
    clock = Clock(dut.clk_i, CLK_PERIOD, units="ps")

    # Start the clock. Start it low to avoid issues on the first RisingEdge
    clock_thread = cocotb.start_soon(clock.start(start_high=False))

    # Launch input and output testbench threads
    input_thread = cocotb.start_soon(input_side_testbench(dut, seed))
    output_thread = cocotb.start_soon(output_side_testbench(dut, seed))

    # Reset initialization
    dut.reset_i.value = 1

    # Wait for 5 clock cycles
    await Timer(CLK_PERIOD*5, units="ps")
    await RisingEdge(dut.clk_i); await Timer(1, units="ps")

    # Deassert reset
    dut.reset_i.value = 0

    # Wait for threads to finish
    await input_thread
    await output_thread

    # Wait for 5 clock cycles
    await Timer(CLK_PERIOD*5, units="ps")
    await RisingEdge(dut.clk_i); await Timer(1, units="ps")

    # Assert reset
    dut.reset_i.value = 1

    # Wait for 5 clock cycles
    await Timer(CLK_PERIOD*5, units="ps")

    # Test finished!
    dut._log.info("Test finished! Current reset_i value = %s", dut.reset_i.value)
