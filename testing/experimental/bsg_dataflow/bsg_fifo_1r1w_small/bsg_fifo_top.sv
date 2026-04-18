`include "bsg_defines.sv"
`include "bsg_fifo_if.sv"
`include "bsg_fifo_uvm_pkg.sv"

module top;

    logic clk;
    import bsg_fifo_uvm_pkg::*; 

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Interface
    fifo_if p_if(clk);
    fifo_env env;

    // 2. Map signals to bsg_fifo_1r1w_small
    bsg_fifo_1r1w_small #(
        .width_p(8),  // Changed to 8 to match your interface logic [7:0]
        .els_p(16)
    ) dut (
        .clk_i(clk),
        .reset_i(~p_if.rst_n), 

        // Input side (Driver)
        .data_i(p_if.data_in),
        .v_i(p_if.v_i),              // Use the new interface name
        .ready_param_o(p_if.ready_o), // BaseJump port name is ready_param_o

        // Output side (Monitor)
        .data_o(p_if.data_out),
        .v_o(p_if.v_o),              // Use the new interface name
        .yumi_i(p_if.yumi_i)         // Use the new interface name
    );

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, top);

        // Reset Sequence
        p_if.rst_n = 0;
        p_if.v_i = 0;    // Signal names updated
        p_if.yumi_i = 0;

        #50;
        p_if.rst_n = 1;

        // Initialize Environment
        env = new(p_if);

        // Start Components
        fork
            env.drv.run();
            env.mon.run();
        join_none

        // Run simulation
        #2000;

        env.sb.report();
        $display("Simulation Finished");
        $finish;
    end

endmodule
