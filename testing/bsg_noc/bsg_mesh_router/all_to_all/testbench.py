import cocotb
from cocotb.triggers import RisingEdge, Timer

# Port index for Processor
P = 0 

@cocotb.test()
async def mesh_test_multi_node(dut):
    dut._log.info("Starting Python Mesh Controller (Top-Level Link Mode)...")

    # 1. WAIT FOR RESET
    # We synchronize to the existing SV clock and wait for hardware reset to finish.
    await Timer(100, units="ns")
    await RisingEdge(dut.clk)
    dut._log.info("Mesh is out of reset.")

    # 2. PACKET CONSTRUCTION
    # [Data(32b)][Y(2b)][X(2b)] -> Target (1,1)
    dest_x, dest_y = 1, 1
    data_payload = 0xABCD
    packet_val = (data_payload << 4) | (dest_y << 2) | dest_x
    
    # Vector: [Packet][Valid(Bit 1)][Ready(Bit 0)] -> 0b...10 (0x2)
    injection_vector = (packet_val << 2) | 0x2
    
    # 3. TOP-LEVEL INJECTION
    # Instead of dut.ty[0].tx[0].tile.link_li, we use the global array in the testbench
    # Syntax for 3D arrays in Cocotb: dut.name[y][x][port]
    try:
        # Accessing Y=0, X=0, Port=P
        input_wire = dut.link_li[0][0][P]
        output_wire = dut.link_lo[0][0][P]
    except (TypeError, AttributeError):
        # Fallback if VCS flattened the array into a single name string
        input_wire = getattr(dut, "link_li[0][0][0]")
        output_wire = getattr(dut, "link_lo[0][0][0]")

    # 4. DRIVE AND HANDSHAKE
    input_wire.value = injection_vector
    await RisingEdge(dut.clk)

    # Check Bit 0 of output (Ready)
    if not (int(output_wire.value) & 0x1):
        while not (int(output_wire.value) & 0x1):
            await RisingEdge(dut.clk)

    input_wire.value = 0
    dut._log.info("Packet injected into Mesh.")

    # 5. MONITOR DESTINATION (1,1)
    try:
        dest_wire = dut.link_lo[1][1][P]
    except (TypeError, AttributeError):
        dest_wire = getattr(dut, "link_lo[1][1][0]")

    found = False
    for cycle in range(100):
        await RisingEdge(dut.clk)
        val = int(dest_wire.value)
        if (val >> 1) & 0x1: # Valid bit
            received_data = (val >> 6) & 0xFFFFFFFF
            dut._log.info(f"MATCH! Received: {hex(received_data)} at cycle {cycle}")
            assert received_data == data_payload
            found = True
            break

    if not found:
        raise TimeoutError("Packet lost!")