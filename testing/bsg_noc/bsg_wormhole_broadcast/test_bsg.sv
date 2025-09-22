// ================================================================
// test_bsg.sv
//

`timescale 1ns/1ps

module test_bsg;

   logic clk_li, reset_li;

  //-----------------------------------------------------------------
  // Clock and reset generation
  //-----------------------------------------------------------------
  initial begin
    clk_li = 0;
    forever #5 clk_li = ~clk_li;
  end

   localparam width_lp = 32;
   localparam payload_len_bits_lp = 4;
   
   localparam coord_bits_lp = 4;

   logic [width_lp-1:0] data_li;
   logic [1:0][width_lp-1:0] data_lo;
   
   logic 	v_li, ready_lo;
   logic [1:0]  ready_and_li, v_lo;
   
   
   bsg_wormhole_broadcast
      #(.width_p            (width_lp           )
	,.payload_len_bits_p(payload_len_bits_lp)
	,.coord_bits_p      (coord_bits_lp      )
	) wm
	(.clk_i       (clk_li)
	 ,.reset_i    (reset_li)

	 ,.v_i        (v_li)
	 ,.data_i     (data_li)
	 ,.ready_and_o(ready_and_lo)

	 ,.v_o        (v_lo)
	 ,.data_o     (data_lo)
	 ,.ready_and_i(ready_and_li)
	 );

   // add backpressure
   always @(posedge clk_li)
     begin
	ready_and_li[0] = 1'b1;
	
	if (reset_li)
	  ready_and_li[1] = 1'b1;
	else
	  ready_and_li[1] = !ready_and_li[1];
     end
   
   genvar 	i;

   wire yumi_li = ready_and_lo & v_li;
   
   for (i = 0; i < 2; i++)
     always @(negedge clk_li)
       if ( (reset_li === 1'b0) && v_lo[i] && ready_and_li[i])
	 $display("%t %d: %h",$time,i, data_lo[i]);
   
   initial
     begin
	v_li = 1'b0;
	reset_li = 1'b1;
	@(negedge clk_li);
	@(negedge clk_li);
	@(negedge clk_li);
	reset_li = 1'b0;
	@(negedge clk_li);
	v_li = 1'b1;
	// first packet, to local node
	data_li = { 24'b0, 4'h2, 4'h0 };
	@(negedge clk_li);	
	data_li =  32'hBEEF_0000;
	@(negedge clk_li);	
	data_li =  32'hBEEF_0001;

	@(negedge clk_li);	
	// second packet, broadcast
	data_li = { 22'b0, 4'h2, 4'hF };
	do @(negedge clk_li); while (!yumi_li);
	
	data_li =  32'hBEEF_0002;
	do @(negedge clk_li); while (!yumi_li);

	data_li =  32'hBEEF_0003;
	do @(negedge clk_li); while (!yumi_li);

	// second packet, pass-thru
	data_li = { 22'b0, 4'h2, 4'h3 };
	do @(negedge clk_li); while (!yumi_li);

	data_li =  32'hBEEF_0004;
	do @(negedge clk_li); while (!yumi_li);

	data_li =  32'hBEEF_0005;
	do @(negedge clk_li); while (!yumi_li);

	data_li = { 22'b0, 4'h0, 4'h3 };
	do @(negedge clk_li); while (!yumi_li);

	data_li = { 22'b0, 4'h0, 4'hF };
	do @(negedge clk_li); while (!yumi_li);

	data_li = { 22'b0, 4'h0, 4'h0 };
	do @(negedge clk_li); while (!yumi_li);

	v_li = 1'b0;
	@(negedge clk_li);	
	$finish;
     end
	
   
endmodule
