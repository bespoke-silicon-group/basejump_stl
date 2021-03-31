
module bsg_link_oddr_phy

 #(parameter width_p = "inv")

  (// reset, data and ready signals synchronous to clk_i
   // no valid signal required (assume valid_i is constant 1)
   input                      reset_i
  ,input                      clk_i
  ,input [1:0][width_p-1:0]   data_i
  ,output                     ready_o
   // output clock and data
  ,output logic [width_p-1:0] data_r_o
  ,output logic               clk_r_o
  );
  
  logic odd_r, clk_r, reset_i_r;  
  logic [1:0][width_p-1:0] data_i_r;
  logic clk_r_o_buf;
  logic [width_p-1:0] data_r_o_buf;
  
  // ready to accept new data every two cycles
  assign ready_o = ~odd_r;
  
  // register 2x-wide input data in flops
  always_ff @(posedge clk_i)
    if (~odd_r)
        data_i_r <= data_i;
        
  // odd_r signal (mux select bit)
  always_ff @(posedge clk_i)
    if (reset_i)
        odd_r <= 1'b0;
    else 
        odd_r <= ~odd_r;
  
  // reset_i is sync to posedge of clk_i, while clk_r is sync to negedge.
  // This will potentially become critical path (only 1/2 period max delay).
  // Add an extra flop for clk_r reset.
  always_ff @(posedge clk_i)
    reset_i_r <= reset_i;
  
  // clock output
  always_ff @(negedge clk_i)
  begin
    if (reset_i_r)
        clk_r <= 1'b0;
    else 
        clk_r <= ~clk_r;
    // Logically, clk_o launch flop is not necessary
    // Add launch flop for clk_o signal for two reasons:
    // 1. Easier to center-align with data bits on ASIC (symmetric to data launch flops)
    // 2. Pack-up register into IOB on FPGA
    clk_r_o_buf <= clk_r;
  end

  SC7P5T_CKBUFX2_SSC14R BSG_ODDR_CKBUF_DONT_TOUCH
  (.CLK(clk_r_o_buf),.Z(clk_r_o));
  
  // data launch flops
  // odd_r is not a reset; should not need to put a reset in here

  always_ff @(posedge clk_i)
    if (odd_r) 
        data_r_o_buf <= data_i_r[0];
    else 
        data_r_o_buf <= data_i_r[1];

  for (genvar i = 0; i < width_p; i++)
  begin: data
    SC7P5T_BUFX2_SSC14R BSG_ODDR_BUF_DONT_TOUCH
    (.A(data_r_o_buf[i]),.Z(data_r_o[i]));
  end

endmodule
