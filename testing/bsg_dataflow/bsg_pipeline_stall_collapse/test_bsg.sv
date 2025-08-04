`include "bsg_defines.sv"

module test_bsg
  ();

   logic [31:0] counter;
      
initial
  begin
     $display("starting...");
     counter = 0;
  end

   wire clk_lo;
   logic reset_lo;
   
   always @(posedge clk_lo)
     begin
	if (reset_lo)
	  counter <= 0;
	else
	  counter <= counter + 1;

	if (counter > (1 << 5))
	  $finish("DONE");
     end

   bsg_nonsynth_clock_gen #(.cycle_time_p(10)
			    ) cfg
     (.o(clk_lo)
      );

   initial 
     begin
	reset_lo = 1'b1;
	#55;
	reset_lo = 1'b0;
     end

   logic [15:0] data_lo;
   logic       v_lo, v_li, ready_li, ready_lo;
   
   dut mydut (.clk_i(clk_lo)
	      ,.reset_i(reset_lo)

	      ,.v_i(v_li)
	      ,.ready_and_o(ready_lo)
	      ,.data_i( { counter, counter })

	      ,.v_o(v_lo)
	      ,.data_o(data_lo)
	      ,.ready_and_i(ready_li)
	      );

//   assign v_li     = 1'b1;
//   assign ready_li = 1'b1;

   assign v_li     = counter[0];
   assign ready_li = ~counter[0];
    
   always @(negedge clk_lo)
       $display("reset=%d v_i=%d data_i=%x ready_o=%d v_o=%d data_o=%d ready_i=%d",reset_lo, v_li, {counter, counter}, ready_lo, v_lo, data_lo, ready_li);
   
endmodule
     
   
   
