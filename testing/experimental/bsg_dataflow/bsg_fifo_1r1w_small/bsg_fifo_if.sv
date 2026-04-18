interface fifo_if(input logic clk);
    logic rst_n;
    logic [7:0] data_in;
    logic [7:0] data_out;
    
    // Handshake signals
    logic v_i;       // Valid in 
    logic ready_o;   // Ready out 
    logic v_o;       // Valid out 
    logic yumi_i;    // Yumi in 

    // Driver Clocking Block
    clocking drv_cb @(posedge clk);
        output rst_n, data_in, v_i, yumi_i;
        input  ready_o, v_o;
    endclocking

    // Monitor Clocking Block
    clocking mon_cb @(posedge clk);
        input data_in, data_out, v_i, yumi_i, ready_o, v_o;
    endclocking

endinterface
