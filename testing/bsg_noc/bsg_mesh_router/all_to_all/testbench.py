import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

P, W, E, N, S = 0, 1, 2, 3, 4

@cocotb.test()
async def mesh_test_multi_node(dut):
    # Setup Clock
    # (The SV code has a clock gen, but Cocotb can drive clk_i directly 
    # if you remove the SV nonsynth_clock_gen)
    
    # Configuration (pulling from the parameters in the DUT)
    num_x = dut.num_tiles_x_p.value
    num_y = dut.num_tiles_y_p.value
    dut._log.info(f"Testing {num_x}x{num_y} Mesh")

    # reset
    dut.reset.value = 1
    await Timer(50, units="ns")
    dut.reset.value = 0
    await RisingEdge(dut.clk)

    # inject traffic
    
    source_tile = dut.ty[0].tx[0].tile
    dest_x, dest_y = 1, 1 # Targeting Tile (1,1)
    
    packet = (dest_y << 4) | (dest_x << 2) | 0 
    
    source_tile.link_i.data.value = packet
    source_tile.link_i.v.value = 1
    
    # monitor completion
    while True:
        await RisingEdge(dut.clk)
        done_bits = dut.done_lo.value.integer
        # If all bits are 1, the whole mesh is done
        if done_bits == (1 << (num_x * num_y)) - 1:
            dut._log.info("Mesh simulation complete and successful!")
            break