module test_bsg
#(parameter width_p=4, 
  parameter output_width_p=2*width_p-1,
  parameter cycle_time_p=10,
  parameter reset_cycles_lo_p=0,
  parameter reset_cycles_hi_p=1
  );
  
  wire clk_lo;
  logic reset;

  bsg_nonsynth_clock_gen #(  .cycle_time_p(cycle_time_p)
                          )  clock_gen
                          (  .o(clk_lo)
                          );

  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(reset_cycles_lo_p)
                           , .reset_cycles_hi_p(reset_cycles_hi_p)
                          )  reset_gen
                          (  .clk_i        (clk_lo) 
                           , .async_reset_o(reset)
                          );

  logic [31:0] ctr;
  
  always @(posedge clk_lo)
    if (reset)
      ctr <= '0;
  else	
      ctr <= ctr + 1'b1;

  wire [output_width_p-1:0] res;

  bsg_adder_one_hot #(.width_p(width_p),.output_width_p(output_width_p))
  foo (.a_i(1'b1 << ctr[1:0]), .b_i(1'b1 << ctr[3:2]), .o(res));
  
  always @(negedge clk_lo)
    begin
      $display("%b %b -> %b\n", 1 << ctr[1:0], 1 << ctr[3:2], res);
      if (ctr == 5'b10000)
        $finish();
    end	
  
endmodule