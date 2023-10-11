`include "bsg_defines.v"

`include "config_defs.v"

`define half_period 1

module cfg_tag_tb();

// double underscore __ separates test packet for each node
localparam test_vector_bits_lp = 319;
localparam test_vector_lp      = 319'b0_0_001101010101_0_101010101001_0_110100000110_0_00000001_0_00111101_0_10__0_0_001001010101_0_101010101111_0_111100000000_0_00000001_0_00111101_0_10__0_0_000101010101_0_101010101001_0_111100000110_0_00000001_0_00111101_0_10__0_0_000001010101_0_101010101111_0_111100000000_0_00000001_0_00111101_0_10__0_0_111101010101_0_101010101111_0_111100000000_0_00000001_0_00111101_0_10__11111111111111;

logic clk_cfg;
logic rst_cfg;
logic clk;
logic rst_dst;
config_s test_config;
logic credit, valid,credit_t;
logic [31:0] data;
logic [2:0] credit_counter;

// clock and reset generator
initial begin
  clk_cfg = 1;
  rst_cfg = 1;
  clk = 1;
  rst_dst = 1;
  #15 rst_cfg = 0;
  #10 rst_dst = 0;
  #10 rst_dst = 1;
  #10 rst_dst = 0;
  $display ("---------------------------------------------- reset -------------------------------------------------\n");
  
  // Display some signals for debug
  $display ("valid\t data \t\t cfg_tag_data exp_ID\n");
  $monitor ("%b\t %h\t\t %h\t\t %d\n" , valid , data,cfg_tag_inst.data,cfg_tag_inst.cfgtagGW.exp_ID_r);

  #1000000 $finish;
end


always #15 begin
  clk_cfg = ~clk_cfg;
end

always #5 begin
  clk = ~clk;
end

cfgtag      #(.packet_ID_width_p(4)
              ,.RELAY_NUM(5)
              ) 
  cfg_tag_inst  (.clk(clk)  
              ,.reset(rst_dst) 
              ,.cfg_clk_i(clk_cfg) 
              ,.cfg_bit_i(test_config.cfg_bit) 
                   
              ,.credit_i(credit)
              ,.valid_o(valid)
              ,.data_o(data)
              );

  
// instantiate config_setter to read configuration bits from localparams
config_setter #(.setter_vector_p(test_vector_lp),
                .setter_vector_bits_p(test_vector_bits_lp) )
  inst_setter  (.clk_i(clk_cfg),
                .reset_i(rst_cfg),
                .config_o(test_config) ); // not connected in simulation testbench


// Keeps count of how many elements are in the FIFO.
fifo_counter #(3) crdit_cnt (.up_count(valid),   // validIn
		  .down_count(credit),  // thanksIn
		  .num_entries(credit_counter),
		  .reset(rst_cfg),
		  .clk(clk));

vcsdumper dumpp ();

// The packets become available to the core at positive edge of the clock, to be synchronous
always_ff @ (posedge clk)
  begin
    credit_t <= valid;
    credit   <= credit_t;
  end

always @ (negedge clk)
  if (credit_counter>3'b100)
    begin
      $display ("credit run out\n");
      $stop;
    end

endmodule
