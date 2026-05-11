import cocotb
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def mesh_test_multi_node(dut):
    """
    Python Mesh Controller:
    Tests a packet route from Tile (0,0) to Tile (1,1)
    using bit-vector driving for flattened VCS signals.
    """
    dut._log.info("Starting Python Mesh Controller (Bit-Vector Mode)...")

    # 1. HIERARCHY ACCESS
    try:
        tile00 = getattr(dut, "ty[0].tx[0].tile")
        tile11 = getattr(dut, "ty[1].tx[1].tile")
        dut._log.info("Successfully hooked into Mesh Hierarchy.")
    except AttributeError:
        dut._log.error("Failed to access tiles. Check naming in previous logs.")
        return

    # 2. WAIT FOR RESET
    # We synchronize to the existing SV clock and wait for the hardware reset to finish.
    dut._log.info("Waiting for SystemVerilog Reset (rg0) to settle...")
    await Timer(100, units="ns")
    await RisingEdge(dut.clk)
    dut._log.info("Mesh is out of reset and ready.")

    # 3. PACKET CONSTRUCTION
    # Format: [Data(32b)][Y_coord(2b)][X_coord(2b)]
    dest_x, dest_y = 1, 1
    data_payload = 0xABCD
    packet_val = (data_payload << 4) | (dest_y << 2) | dest_x
    
    # 4. INJECTION (BIT-VECTOR DRIVING)
    # Total vector = [Packet(32:2)][Valid(1)][Ready(0)]
    # To set Valid=1, we shift packet left by 2 and OR with 2 (binary 10)
    injection_vector = (packet_val << 2) | 0x2
    
    dut._log.info(f"Injecting into (0,0) with vector: {bin(injection_vector)}")
    
    # Drive the flattened link_li handle
    tile00.link_li.value = injection_vector
    
    await RisingEdge(dut.clk)
    # Check if backpressure (Ready) is high from the router
    # Bit 0 of link_lo is the 'ready_and_rev' signal
    if not (tile00.link_lo.value & 0x1):
        dut._log.warning("Router not ready, holding valid...")
        while not (tile00.link_lo.value & 0x1):
            await RisingEdge(dut.clk)
            
    tile00.link_li.value = 0 # Clear injection
    dut._log.info("Injection successful. Monitoring (1,1)...")

    # 5. MONITORING ARRIVAL
    # Watch Tile (1,1) Local Output (link_lo)
    found = False
    for cycle in range(100):
        await RisingEdge(dut.clk)
        
        # Check Bit 1 (Valid) of the destination's output link
        # Format: [Data(33:2)][Valid(1)][Ready(0)]
        lo_val = tile11.link_lo.value
        
        if (lo_val >> 1) & 0x1:
            # Extract data: shift right by 2 to clear Valid and Ready bits
            # Then shift right by 4 to clear X/Y routing bits
            received_raw = (lo_val >> 2)
            received_data = (received_raw >> 4) & 0xFFFFFFFF
            
            dut._log.info(f"MATCH! Packet arrived at (1,1) in {cycle} cycles.")
            dut._log.info(f"Received Payload: {hex(received_data)}")
            
            assert received_data == data_payload, f"Data mismatch! Got {hex(received_data)}"
            found = True
            break

    if not found:
        dut._log.error("TIMEOUT: Packet never reached destination.")
        raise TimeoutError("Mesh routing failed or packet lost.")

    dut._log.info("Test complete.")