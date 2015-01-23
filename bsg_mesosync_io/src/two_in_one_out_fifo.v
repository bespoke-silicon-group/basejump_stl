//`timescale 1ns / 1ps
//
// CSE141L Lab 2, Part 1: FIFO
// University of California, San Diego
// 
// Written by Michael Taylor, May 1, 2010
// 
// Upgraded the FIFO, to have two input bits and one output bit, by Moein Khazraee, Nov. 2014
//
// parameters:
//  LG_DEPTH: lg (number of elements+1)
//  ALMOST_DIST: number of enteries for almost full

module two_in_one_out_fifo #(LG_DEPTH=6)
  (input clk
 	 ,input [1:0] din
 	 ,input enque 
 	 ,input deque	
 	 ,input clear
 	 ,output dout
 	 ,output empty
 	 ,output full
 	 ,output valid
   );

// some storage
reg [1:0] storage [(2**(LG_DEPTH-1))-1:0];

// Counter of number of available values, which needs to
// be 1 bit more in width
reg [LG_DEPTH:0]   count_r;
// one read pointer, one write pointer;
// There is no use for another msb, since it overflows
reg [LG_DEPTH-2:0] wptr_r;
reg [LG_DEPTH-1:0] rptr_r;

reg error_r; // lights up if the fifo was used incorrectly

assign full        = (count_r == {1'b1,{LG_DEPTH{1'b0}}});
assign empty       = (count_r == 0);
assign valid       = !empty;

// First MSB is sent out, then the LSB, to keep input order
// hence the first bit of read pointer is reversed
assign dout = storage[rptr_r[LG_DEPTH-1:1]][~(rptr_r[0])];

always @(posedge clk)
 if (enque)
	storage[wptr_r] <= din;

// keeping track of number of entries and updating read and 
// write poniteres, and displaying errors in case of overflow
// or underflow
always @(posedge clk)
  begin
     if (clear)
		begin
			rptr_r  <= 0;
			wptr_r  <= 0;
			count_r <= 0;
      error_r <= 1'b0;
		end
     else
		begin
			rptr_r  <= rptr_r  + deque;
			wptr_r  <= wptr_r  + enque;
      count_r <= count_r + (enque << 1) - deque;

			//synopsys translate_off
			if (full & enque)
					$display("%m error: wrote full fifo at time %t", $time);
			if (empty & deque)
					$display("%m error: deque empty fifo at time %t", $time);			
			//synopsys translate_on				
								
			error_r <= error_r | (full & enque) | (empty & deque);
		end 
  end

endmodule
