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
ITERATION = 350

# Flow control random seed
# Use different seeds on input and output sides for more randomness
CTRL_INPUT_SEED  = 1
CTRL_OUTPUT_SEED = 2

# Testbench clock period
CLK_PERIOD = 10

async def allow_enq_deq_on_full_p(dut, data_random):
    # Check DUT ready signal OR we are reading (passthrough)
    if dut.ready_param_o.value == 1 or (dut.yumi_i.value == 1 and dut.v_o.value == 1):
        # Assert DUT valid signal
        dut.v_i.setimmediatevalue(1)
        # Generate send data
        value = math.floor(data_random.random()*pow(2, WIDTH_P))
        # print(f"Sent {value}")
        dut.data_i.setimmediatevalue(value)
        # iteration increment
        return True

    # Deassert DUT valid signal
    dut.v_i.setimmediatevalue(0)

    return False

async def default(dut, data_random):
    # Assert DUT valid signal
    dut.v_i.setimmediatevalue(1)
    # Check DUT ready signal
    if dut.ready_param_o.value == 1:
        # Generate send data
        value = math.floor(data_random.random()*pow(2, WIDTH_P))
        # print(f"Sent {value}")
        dut.data_i.setimmediatevalue(value)
        return True
    return False


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

    # Wait for reset deassertion
    while 1:
        await RisingEdge(dut.clk_i); await Timer(1, units="ps")
        if dut.reset_i == 0: break

    # Main iterations
    i = 0
    while 1:
        await RisingEdge(dut.clk_i); await Timer(2, units="ps")
        # Half chance to send data flit
        if control_random.random() >= 0.5:
            iteration = False

            if dut.allow_enq_deq_on_full_p.value == 1:
                iteration = await allow_enq_deq_on_full_p(dut, data_random)
            else:
                iteration = await default(dut, data_random)

            if iteration:
                # iteration increment
                i += 1
                # Check iteration
                if i == ITERATION:
                    # Test finished
                    break
        else:
            # Deassert DUT valid signal
            dut.v_i.setimmediatevalue(0)

    await RisingEdge(dut.clk_i); await Timer(1, units="ps")
    # Deassert DUT valid signal
    dut.v_i.value = 0


async def output_side_testbench(dut, seed):
    """Handle input traffic"""

    # Create local random generator for data generation
    data_random = random.Random()
    data_random.seed(seed)

    # Create control random generator for flow control
    control_random = random.Random()
    control_random.seed(CTRL_OUTPUT_SEED)

    # Initialize DUT interface values
    dut.yumi_i.value = 0

    # Wait for reset deassertion
    while 1:
        await RisingEdge(dut.clk_i); await Timer(1, units="ps")
        if dut.reset_i == 0: break

    # Main iterations
    i = 0
    while 1:
        await RisingEdge(dut.clk_i); await Timer(1, units="ps")
        if dut.v_o.value == 1 and control_random.random() >= 0.5:
            # Assert DUT yumi signal
            dut.yumi_i.setimmediatevalue(1)
            # Generate check data and compare with receive data
            value = math.floor(data_random.random()*pow(2, WIDTH_P))
            # print(f"Read {value}")
            assert dut.data_o.value == value, f"data mismatch! Expected: {value}, found: {int(str(dut.data_o.value), 2)}"
            # iteration increment
            i += 1
            # Check iteration
            if i == ITERATION:
                # Test finished
                break
        else:
            # Deassert DUT yumi signal
            dut.yumi_i.setimmediatevalue(0)

    await RisingEdge(dut.clk_i); await Timer(1, units="ps")
    # Deassert DUT yumi signal
    dut.yumi_i.value = 0


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
