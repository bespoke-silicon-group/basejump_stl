import math
import time
import random

import cocotb
from cocotb.clock import Clock, Timer
from cocotb.triggers import RisingEdge, FallingEdge, Timer



ITERATION = 50

IN_DIRS = 5
OUT_DIRS = 5

IN_DIRS_MAX_DECIMAL = (1 << IN_DIRS) - 1 # 31
OUT_DIRS_MAX_DECIMAL = (1 << OUT_DIRS) - 1 # 31
IN_DIRS_MAX_DECIMAL = (1 << IN_DIRS) - 1 # 31
OUT_DIRS_MAX_DECIMAL = (1 << OUT_DIRS) - 1 # 31

X_COORD_WIDTH = 2
Y_COORD_WIDTH = 2

X_COORD_MAX_DECIMAL = (1 << X_COORD_WIDTH) - 1
Y_COORD_MAX_DECIMAL = (1 << Y_COORD_WIDTH) - 1
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

    for i in range (ITERATION):
        dut._log.info(f"STARTING TEST {i}")
        await RisingEdge(dut.clk_i)

        # init ports to all 0
        for i in range(IN_DIRS):
            dut.v_i[i].value = 0
            dut.data_i[i].value = 0

        dest_x = rand.randint(0, X_COORD_MAX_DECIMAL)
        dest_y = rand.randint(0, Y_COORD_MAX_DECIMAL)
        dut._log.info(f"  Destination is: ({dest_x}, {dest_y})")
        mc_x = rand.randint(0, 1)
        mc_y = rand.randint(0, 1)
        dut._log.info(f"  Multicast bits are: x: {mc_x}, y: {mc_y}")
        my_x_i = MY_X
        my_y_i = MY_Y

        # determine which direction packet goes with DOR
        dest_ports = []
        if (dest_x < my_x_i):
            dest_ports.append(W)
            
        elif (dest_x > my_x_i):
            dest_ports.append(E)
            
        elif (dest_y < my_y_i):
            dest_ports.append(N)
            
        elif (dest_y > my_y_i):
            dest_ports.append(S)
        else:
            dest_ports.append(P)

        # randomly select a legal output port
        outward_port = dest_ports[0]
        src_port = 0
        if (outward_port == E or outward_port == W):
            # source port must be E, W or P, due to DOR, and not the dest port
            possible_ports = [E, W, P]
            possible_ports.remove(outward_port)
            src_port = random.choice(possible_ports)
        else:
            possible_ports = [N, E, S, W, P]
            possible_ports.remove(outward_port)
            src_port = random.choice(possible_ports)
        dut._log.info(f"  Source port is {src_port}")

        # check multicast condition (requires knowledge of src_port)
        if ((mc_x and ((my_x_i != dest_x) or ((my_x_i == dest_x) and (src_port == E or src_port == W))) or
            mc_y and (my_x_i == dest_x))):
            dest_ports.append(P)
            dut._log.info(f"  Testing multicast condition")
        dut._log.info(f"  Destination ports are: {dest_ports}")

        # create mask for ports that should recv packet
        dest_mask = 0
        for port in dest_ports:
            dest_mask |= (1 << port)

        packet = (dest_y << (2 + X_COORD_WIDTH)) | (dest_x << 2) | (mc_y << 1) | mc_x
        dut._log.info(f"  Data packet: {packet}")

        # ready_and_i = rand.randint(0, OUT_DIRS_MAX_DECIMAL)
        ready_and_i = 0b11111
        outputs_should_accept = False
        if ((dest_mask & ready_and_i) == dest_mask):
            outputs_should_accept = True
            dut._log.info(f"  Destination ports should be ready for input")

        dut.data_i[src_port].value = packet
        dut.v_i[src_port].value = 1
        dut.ready_and_i.value = ready_and_i
        dut.my_x_i.value = my_x_i
        dut.my_y_i.value = my_y_i

        if len(dest_ports) == 1:  # only one dest port
            dest_port = dest_ports[0]
            v_o, data_o, yumi_o = 0, 0, 0
            for _ in range(100):
                await RisingEdge(dut.clk_i)
                await Timer(1, units="ps") 
                if dut.yumi_o.value.is_resolvable and (dut.yumi_o.value >> src_port) & 1:
                    yumi_o = 1
                    dut._log.info(f"  Input port {src_port} accepted input packet!")
                if dut.v_o.value.is_resolvable and (dut.v_o.value >> dest_port) & 1:
                    v_o = 1
                    dut._log.info(f"  Output port {dest_port} asserted valid output!")
                    break

            data_o = dut.data_o[dest_port].value

            if (outputs_should_accept):
                assert yumi_o == 1, f"Input port {src_port} did not accept the input packet (yumi_o low)"
                assert v_o == 1, f"v_o at port {dest_port} not set!"
                assert data_o == packet, f"output data packet at port {dest_port} modified from original!"
            
        else:  # multiple output ports (multicast)
            v_o, data_o, yumi_o = 0, 0, 0
            for _ in range(100):  # wait for yumi
                await RisingEdge(dut.clk_i)
                await Timer(1, units="ps") 
                if dut.yumi_o.value.is_resolvable and (dut.yumi_o.value >> src_port) & 1:
                    yumi_o = 1
                    break
            # TODO this needs to be more sophisticated for when we want to deal with output ports not both being ready instantly
            for port in dest_ports:
                if dut.v_o.value.is_resolvable and (dut.v_o.value >> port) & 1:
                    v_o = 1
                    data_o = dut.data_o[port].value
                if (outputs_should_accept):
                    assert yumi_o == 1, f"Input port {src_port} did not accept the input packet! (yumi_o low)"
                    assert v_o == 1, f"v_o at port {port} not set!"
                    assert data_o == packet, f"output data packet at port {port} modified from original!"

        dut.v_i.value = 0
        dut.ready_and_i.value = 0


    # WORKING TEST:
    # Test a simple send from West port to East with mc_x

    dut._log.info(f"Starting manual test")
    await RisingEdge(dut.clk_i)
    await Timer(1, units="ps")

    src_port = W
    dest_port = E

    dest_x = 2
    dest_y = 1
    mc_x = 1
    mc_y = 0
    packet = (dest_y << (2 + X_COORD_WIDTH)) | (dest_x << 2) | (mc_y << 1) | mc_x

    ready_and_i = ((1 << dest_port) | (1 << P))  # destination port is East and P
    
    my_x_i = MY_X  # (1, 1)
    my_y_i = MY_Y

    await Timer(CLK_PERIOD, units="ps")

    dut.data_i[src_port].value = packet
    dut.v_i[src_port].value = 1
    dut.ready_and_i.value = ready_and_i
    dut.my_x_i.value = my_x_i
    dut.my_y_i.value = my_y_i

    # Wait for input handshake (yumi_o)
    v_o, data_o, yumi_o = 0, 0, 0
    for _ in range(10):
        await RisingEdge(dut.clk_i)
        await Timer(1, units="ps") 
        if dut.yumi_o.value.is_resolvable and (dut.yumi_o.value >> src_port) & 1:
            yumi_o = 1
            dut._log.info(f"Input port {src_port} accepted input packet!")
        if dut.v_o.value.is_resolvable and (dut.v_o.value >> P) & 1:
            v_o_p = 1
            dut._log.info(f"Output port {P} asserted valid output!")
        if dut.v_o.value.is_resolvable and (dut.v_o.value >> dest_port) & 1:
            v_o_e = 1
            dut._log.info(f"Output port {dest_port} asserted valid output!")
            break
    
    
    data_o_e = dut.data_o[dest_port].value
    data_o_p = dut.data_o[P].value

    assert yumi_o == 1, \
        f"Router at {src_port} did not accept the input packet (yumi_o low)"
            
    assert v_o_e == 1, \
        f"v_o at port {dest_port} not set!"
    
    assert v_o_p == 1, \
        f"v_o at port {P} not set!"
    
    assert data_o_e == packet, \
        f"output data packet at port {dest_port} modified from original!"
    
    assert data_o_p == packet, \
        f"output data packet at port {P} modified from original!"



    dut.v_i.value = 0
    dut.ready_and_i.value = 0

    dut._log.info("Test finished!")